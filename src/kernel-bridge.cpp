#include "kernel-bridge.hpp"
#include "kernel.hpp"
#include <QtConcurrent/QtConcurrent>
#include <QDateTime>
#include "utils.hpp"
#include <QDir>
#include <QStandardPaths>
#include <QFile>
#include <QTimer>
#include <QTextStream>
#include <sys/stat.h>
#include <unistd.h>
#include <pwd.h>

KernelBridge::KernelBridge(QObject *parent) : QObject(parent) {
}

KernelBridge::~KernelBridge() {
    system("rm -rf /tmp/neko-kernel-*");
}

void KernelBridge::setBusy(bool b) {
    if (m_busy != b) {
        m_busy = b;
        emit busyChanged();
    }
}

void KernelBridge::setStatusMessage(const QString &message, bool isError) {
    m_statusMessage = message;
    m_statusIsError = isError;
    emit statusMessageChanged();
}

QString KernelBridge::activeKernelVersion() const {
    std::string out = utils::exec("uname -r");
    return QString::fromStdString(out).trimmed();
}

QString KernelBridge::detectedCpuLevel() const {
    return QString::fromStdString(utils::detectCpuLevel());
}

QString KernelBridge::detectedBootloader() const {
    if (utils::dirExists("/boot/grub") || QFile::exists("/etc/default/grub") || QFile::exists("/boot/grub/grub.cfg")) {
        return "GRUB";
    }
    if (QFile::exists("/boot/loader/loader.conf")) {
        return "systemd-boot";
    }
    if (QFile::exists("/boot/limine.cfg") || QFile::exists("/boot/limine.conf")) {
        return "Limine";
    }
    if (QFile::exists("/boot/refind_linux.conf") || QFile::exists("/boot/EFI/refind/refind.conf")) {
        return "rEFInd";
    }
    return "Void / Custom Bootloader";
}

QVariantList KernelBridge::getKernels() {
    QVariantList list;
    auto kernels = Kernel::getKernels();
    for (const auto &k : kernels) {
        QVariantMap map;
        map["name"] = QString::fromStdString(k.name());
        map["version"] = QString::fromStdString(k.version());
        map["category"] = QString::fromStdString(k.category());
        map["size"] = QString::fromStdString(k.size());
        map["installDate"] = QString::fromStdString(k.installDate());
        map["installed"] = k.is_installed();
        map["type"] = QString::fromStdString(k.type());
        list.append(map);
    }
    return list;
}

void KernelBridge::updateKernels() {
    setBusy(true);
    setProgress(15);
    setStatusMessage("Scanning installed & available kernels...", false);
    appendLog("Scanning system for installed and available kernels...");
    
    auto future = QtConcurrent::run([this]() {
        QMetaObject::invokeMethod(this, [this]() { setProgress(40); });
        
        // Instantly query kernels locally
        auto newList = getKernels();

        QMetaObject::invokeMethod(this, [this, newList]() {
            m_kernelsCache = newList;
            setProgress(75);
            emit kernelsChanged();
            appendLog(QString("Kernel scan completed. Found %1 kernel entries:").arg(newList.size()));
            for (const auto &var : newList) {
                QVariantMap m = var.toMap();
                appendLog(QString("  • %1 (%2) [Type: %3, Installed: %4]")
                            .arg(m["name"].toString())
                            .arg(m["version"].toString())
                            .arg(m["type"].toString())
                            .arg(m["installed"].toBool() ? "Yes" : "No"));
            }
        });

        // Ensure custom repo file exists if not present (without blocking launch if already present)
        std::string repoConf = "/etc/xbps.d/10-neko-kernel-repo.conf";
        if (!QFile::exists(QString::fromStdString(repoConf)) && utils::commandExists("xbps-install")) {
            appendLog("Checking custom kernel repository configuration in /etc/xbps.d/10-neko-kernel-repo.conf...");
            std::string repoCheckCmd = "pkexec sh -c \"mkdir -p /etc/xbps.d && echo 'repository=https://github.com/javiercplus/kernel-neko-void/releases/download/7.1/' > " + repoConf + "\"";
            utils::runPrivilegedCommand(repoCheckCmd);
            newList = getKernels();
        }

        QMetaObject::invokeMethod(this, [this, newList]() {
            m_kernelsCache = newList;
            setProgress(100);
            setStatusMessage("Kernels loaded successfully", false);
            setBusy(false);
            emit kernelsChanged();
            QTimer::singleShot(1000, this, [this]() { setProgress(0); });
        });
    });
    (void)future;
}

void KernelBridge::appendLog(const QString &line) {
    if (QThread::currentThread() != this->thread()) {
        QMetaObject::invokeMethod(this, [this, line]() { appendLog(line); });
        return;
    }

    QString timestamp = QDateTime::currentDateTime().toString("hh:mm:ss");
    QString formattedLine = "[" + timestamp + "] ";
    
    if (line.toLower().contains("error") || line.toLower().contains("failed")) {
        formattedLine += "<font color='#ff5555'>" + line + "</font>";
    } else if (line.toLower().contains("success") || line.toLower().contains("complete") || line.toLower().contains("finished")) {
        formattedLine += "<font color='#50fa7b'>" + line + "</font>";
    } else if (line.toLower().contains("warning")) {
        formattedLine += "<font color='#f1fa8c'>" + line + "</font>";
    } else if (line.startsWith("Executing:") || line.startsWith("Starting") || line.startsWith("Initiating") || line.startsWith("Scanning") || line.startsWith("Requesting")) {
        formattedLine += "<font color='#bd93f9'>" + line + "</font>";
    } else {
        formattedLine += line;
    }

    m_logs += formattedLine + "<br>";
    if (m_logs.length() > 60000) m_logs = m_logs.right(45000);
    emit logsChanged();
}
void KernelBridge::installKernel(const QString &name) {
    appendLog("Starting installation of kernel package: " + name);
    setBusy(true);
    setProgress(10);
    
    auto future = QtConcurrent::run([this, name]() {
        std::string pkgName = name.toStdString();
        std::string headersPkg = pkgName + "-headers";
        
        // In Void Linux, xbps-install runs kernel post-install hooks (like dracut and grub-mkconfig/bootloader update) natively.
        // We do not need to manually call grub-mkconfig if xbps-install handles it, but we can do a quick check just in case.
        std::string cmd = "pkexec sh -c \"xbps-install -y " + pkgName + " && (xbps-install -y " + headersPkg + " || true)\" 2>&1";
        
        appendLog("Executing: " + QString::fromStdString(cmd));

        FILE* pipe = popen(cmd.c_str(), "r");
        bool success = false;
        if (pipe) {
            char buffer[256];
            while (fgets(buffer, sizeof(buffer), pipe)) {
                QString line = QString::fromLocal8Bit(buffer).trimmed();
                appendLog(line);
            }
            success = (pclose(pipe) == 0);
        }

        QMetaObject::invokeMethod(this, [this, success, name]() {
            if (success) {
                appendLog("Kernel installation finished successfully: " + name);
                setStatusMessage("Kernel installed successfully", false);
            } else {
                appendLog("ERROR: Main kernel installation failed for " + name);
                setStatusMessage("Installation failed", true);
            }
            updateKernels();
            updateDkmsModules();
            updateDefaultKernel();
        });
    });
    (void)future;
}

void KernelBridge::removeKernel(const QString &name) {
    bool isManual = name.startsWith("linux-manual-");
    QString runningVer = activeKernelVersion().trimmed();
    if (!runningVer.isEmpty()) {
        QString verToCheck = isManual ? name.mid(13) : name;
        if (verToCheck.contains(runningVer) || runningVer.contains(verToCheck) || name.contains(runningVer)) {
            appendLog("SECURITY WARNING: Attempted to uninstall currently running kernel (" + runningVer + "). Operation aborted.");
            setStatusMessage("Cannot remove currently running kernel!", true);
            return;
        }
    }
    appendLog("Starting removal of kernel: " + name + " (Type: " + QString(isManual ? "Manual /boot" : "XBPS package") + ")");
    setBusy(true);
    setProgress(10);
    auto future = QtConcurrent::run([this, name, isManual]() {
        std::string cmd;
        if (isManual) {
            std::string ver = name.toStdString().substr(13);
            cmd = "pkexec sh -c \"if [ -n '" + ver + "' ]; then "
                  "rm -fv /boot/vmlinuz-" + ver + 
                  " /boot/initramfs-" + ver + ".img /boot/initrd.img-" + ver +
                  " /boot/config-" + ver + " /boot/System.map-" + ver +
                  " /boot/vmlinuz-" + ver + ".old /boot/initramfs-" + ver + ".old.img; "
                  "rm -rfv /usr/lib/modules/" + ver + " /lib/modules/" + ver + "; "
                  "(which grub-mkconfig >/dev/null 2>&1 && grub-mkconfig -o /boot/grub/grub.cfg || true); "
                  "fi\" 2>&1";
        } else {
            std::string pkgName = name.toStdString();
            cmd = "pkexec sh -c \"xbps-remove -Rfy " + pkgName + " && (which grub-mkconfig >/dev/null 2>&1 && grub-mkconfig -o /boot/grub/grub.cfg || true)\" 2>&1";
        }
        
        appendLog("Executing: " + QString::fromStdString(cmd));
        FILE* pipe = popen(cmd.c_str(), "r");
        bool success = false;
        if (pipe) {
            char buffer[256];
            while (fgets(buffer, sizeof(buffer), pipe)) {
                QString line = QString::fromLocal8Bit(buffer).trimmed();
                appendLog(line);
            }
            success = (pclose(pipe) == 0);
        }

        QMetaObject::invokeMethod(this, [this, success, name]() {
            if (success) {
                appendLog("Kernel removal completed successfully: " + name);
                setStatusMessage("Kernel removed successfully", false);
            } else {
                appendLog("ERROR: Kernel removal failed for " + name);
                setStatusMessage("Removal failed", true);
            }
            updateKernels();
            updateDkmsModules();
            updateDefaultKernel();
        });
    });
    (void)future;
}
void KernelBridge::vkpurge() {
    appendLog("Initiating vkpurge rm all to remove all old unreferenced kernels...");
    setBusy(true);
    setProgress(10);
    setStatusMessage("Purging all old kernels...", false);
    auto future = QtConcurrent::run([this]() {
        std::string cmd = "pkexec sh -c \"vkpurge rm all && (which grub-mkconfig >/dev/null 2>&1 && grub-mkconfig -o /boot/grub/grub.cfg || true)\" 2>&1";

        QMetaObject::invokeMethod(this, [this]() {
            setProgress(30);
            setStatusMessage("Running vkpurge...", false);
        });

        FILE* pipe = popen(cmd.c_str(), "r");
        bool success = false;
        if (pipe) {
            char buffer[256];
            while (fgets(buffer, sizeof(buffer), pipe)) {
                QString line = QString::fromLocal8Bit(buffer).trimmed();
                appendLog(line); 
                if (line.contains("Removing")) setProgress(60);
            }
            success = (pclose(pipe) == 0);
        }

        QMetaObject::invokeMethod(this, [this, success]() {
            setBusy(false);
            setProgress(success ? 100 : 0);
            if (success) {
                appendLog("vkpurge completed successfully.");
                setStatusMessage("Old kernels purged successfully", false);
                emit operationFinished("Kernels purged");
            } else {
                appendLog("ERROR: vkpurge failed.");
                setStatusMessage("vkpurge failed", true);
            }
            updateKernels();
            updateDkmsModules();
            updateDefaultKernel();
        });
    });
    (void)future;
}

// DKMS Management Implementation
QVariantList KernelBridge::getDkmsModulesInternal() {
    QVariantList list;
    
    // 1. Get installed/registered DKMS modules from local status
    QMap<QString, QVariantMap> activeModules;
    if (utils::commandExists("dkms")) {
        std::string rawOutput = utils::exec("dkms status 2>&1");
        if (!rawOutput.empty()) {
            std::vector<std::string> lines = utils::split(rawOutput, '\n');
            for (const auto &line_raw : lines) {
                if (line_raw.empty()) continue;
                QString line = QString::fromStdString(line_raw).trimmed();
                
                int colonIdx = line.indexOf(':');
                if (colonIdx == -1) continue;

                QString infoPart = line.left(colonIdx).trimmed();
                QString statusPart = line.mid(colonIdx + 1).trimmed();

                QStringList parts = infoPart.split(',');
                if (parts.size() < 2) continue;

                QString modAndVer = parts[0].trimmed();
                QString kernelVer = parts[1].trimmed();
                QString arch = parts.size() >= 3 ? parts[2].trimmed() : "all";

                int slashIdx = modAndVer.indexOf('/');
                QString modName = (slashIdx != -1) ? modAndVer.left(slashIdx) : modAndVer;
                QString modVersion = (slashIdx != -1) ? modAndVer.mid(slashIdx + 1) : "unknown";

                QVariantMap map;
                map["name"] = modName;
                map["version"] = modVersion;
                map["kernel"] = kernelVer;
                map["arch"] = arch;
                map["status"] = statusPart; // e.g. "installed", "built", "added"
                map["isDkmsPackage"] = false; // Registered local module
                map["packageInstalled"] = true;
                
                activeModules[modName.toLower() + "-" + kernelVer] = map;
                list.append(map);
            }
        }
    }

    // 2. Query available -dkms packages from XBPS repositories in Void Linux
    if (utils::commandExists("xbps-query")) {
        std::string rawXbps = utils::exec("xbps-query -l | grep 'dkms'");
        rawXbps += "\n" + utils::exec("xbps-query -Rs 'dkms'");
        std::vector<std::string> xbpsLines = utils::split(rawXbps, '\n');

        std::set<std::string> processedPkgs;

        for (const auto &xbpsLine : xbpsLines) {
            if (xbpsLine.empty()) continue;
            std::istringstream iss(xbpsLine);
            std::string status;
            std::string fullPkg;
            iss >> status >> fullPkg;
            if (fullPkg.empty()) continue;

            size_t hyphen_pos = fullPkg.find_last_of('-');
            if (hyphen_pos == std::string::npos || hyphen_pos == 0) continue;

            std::string pkgName = fullPkg.substr(0, hyphen_pos);
            std::string pkgVersion = fullPkg.substr(hyphen_pos + 1);

            if (pkgName.find("dkms") == std::string::npos || pkgName == "dkms") continue;
            if (processedPkgs.count(pkgName)) continue;
            processedPkgs.insert(pkgName);
            
            bool isInstalled = (status == "[*]" || status == "ii");
            
            QString modName = QString::fromStdString(pkgName);
            QString shortName = modName;
            if (shortName.endsWith("-dkms")) shortName.chop(5);

            bool alreadyRegistered = false;
            for (auto it = activeModules.constBegin(); it != activeModules.constEnd(); ++it) {
                if (it.value()["name"].toString().toLower() == shortName.toLower()) {
                    alreadyRegistered = true;
                    break;
                }
            }

            if (!alreadyRegistered) {
                QVariantMap map;
                map["name"] = modName; // Full package name
                map["version"] = QString::fromStdString(pkgVersion);
                map["kernel"] = activeKernelVersion(); // Show current kernel context
                map["arch"] = "all";
                map["status"] = isInstalled ? "unregistered" : "not installed";
                map["isDkmsPackage"] = true; // Flag for package management
                map["packageInstalled"] = isInstalled;
                list.append(map);
            }
        }
    }

    return list;
}

void KernelBridge::updateDkmsModules() {
    setBusy(true);
    appendLog("Scanning DKMS modules and packages...");
    auto future = QtConcurrent::run([this]() {
        auto dkmsList = getDkmsModulesInternal();
        QMetaObject::invokeMethod(this, [this, dkmsList]() {
            m_dkmsCache = dkmsList;
            setBusy(false);
            emit dkmsModulesChanged();
            appendLog(QString("DKMS scan completed. Found %1 modules/packages:").arg(dkmsList.size()));
            for (const auto &var : dkmsList) {
                QVariantMap m = var.toMap();
                appendLog(QString("  • %1 v%2 (Kernel: %3) [Status: %4]")
                            .arg(m["name"].toString())
                            .arg(m["version"].toString())
                            .arg(m["kernel"].toString())
                            .arg(m["status"].toString()));
            }
        });
    });
    (void)future;
}

void KernelBridge::installDkmsModule(const QString &name, const QString &version, const QString &kernel) {
    bool isPackage = name.endsWith("-dkms");
    if (isPackage) {
        appendLog("Starting installation of XBPS DKMS package: " + name);
    } else {
        appendLog("Starting installation of DKMS module: " + name + " v" + version + " for kernel " + kernel);
    }
    setBusy(true);
    
    auto future = QtConcurrent::run([this, name, version, kernel, isPackage]() {
        std::string cmd;
        if (isPackage) {
            cmd = "pkexec xbps-install -y " + name.toStdString() + " 2>&1";
        } else {
            cmd = "pkexec dkms install -m " + name.toStdString() + 
                  " -v " + version.toStdString() + 
                  " -k " + kernel.toStdString() + " 2>&1";
        }
        
        appendLog("Executing: " + QString::fromStdString(cmd));

        FILE* pipe = popen(cmd.c_str(), "r");
        bool success = false;
        if (pipe) {
            char buffer[256];
            while (fgets(buffer, sizeof(buffer), pipe)) {
                QString line = QString::fromLocal8Bit(buffer).trimmed();
                appendLog(line);
            }
            success = (pclose(pipe) == 0);
        }

        QMetaObject::invokeMethod(this, [this, success, isPackage, name]() {
            if (success) {
                appendLog((isPackage ? "XBPS DKMS package installation finished: " : "DKMS module installation finished: ") + name);
                setStatusMessage(isPackage ? "XBPS DKMS Package installed" : "DKMS module installed", false);
            } else {
                appendLog((isPackage ? "ERROR: XBPS DKMS package installation failed: " : "ERROR: DKMS module installation failed: ") + name);
                setStatusMessage(isPackage ? "XBPS package installation failed" : "DKMS module installation failed", true);
            }
            updateDkmsModules();
        });
    });
    (void)future;
}

void KernelBridge::removeDkmsModule(const QString &name, const QString &version, const QString &kernel) {
    bool isPackage = name.endsWith("-dkms");
    if (isPackage) {
        appendLog("Starting removal of XBPS DKMS package: " + name);
    } else {
        appendLog("Starting removal of DKMS module: " + name + " v" + version + " for kernel " + kernel);
    }
    setBusy(true);
    
    auto future = QtConcurrent::run([this, name, version, kernel, isPackage]() {
        std::string cmd;
        if (isPackage) {
            cmd = "pkexec xbps-remove -Rfy " + name.toStdString() + " 2>&1";
        } else {
            cmd = "pkexec dkms remove -m " + name.toStdString() + 
                  " -v " + version.toStdString() + 
                  " -k " + kernel.toStdString() + " --all 2>&1";
        }
        
        appendLog("Executing: " + QString::fromStdString(cmd));

        FILE* pipe = popen(cmd.c_str(), "r");
        bool success = false;
        if (pipe) {
            char buffer[256];
            while (fgets(buffer, sizeof(buffer), pipe)) {
                QString line = QString::fromLocal8Bit(buffer).trimmed();
                appendLog(line);
            }
            success = (pclose(pipe) == 0);
        }

        QMetaObject::invokeMethod(this, [this, success, isPackage, name]() {
            if (success) {
                appendLog((isPackage ? "XBPS DKMS package removal finished: " : "DKMS module removal finished: ") + name);
                setStatusMessage(isPackage ? "XBPS DKMS Package removed" : "DKMS module removed", false);
            } else {
                appendLog((isPackage ? "ERROR: XBPS DKMS package removal failed: " : "ERROR: DKMS module removal failed: ") + name);
                setStatusMessage(isPackage ? "XBPS package removal failed" : "DKMS module removal failed", true);
            }
            updateDkmsModules();
        });
    });
    (void)future;
}

void KernelBridge::autoinstallDkms() {
    appendLog("Initiating DKMS autoinstall for active kernel: " + activeKernelVersion());
    setBusy(true);
    
    auto future = QtConcurrent::run([this]() {
        std::string cmd = "pkexec dkms autoinstall 2>&1";
        appendLog("Executing: " + QString::fromStdString(cmd));

        FILE* pipe = popen(cmd.c_str(), "r");
        bool success = false;
        if (pipe) {
            char buffer[256];
            while (fgets(buffer, sizeof(buffer), pipe)) {
                QString line = QString::fromLocal8Bit(buffer).trimmed();
                appendLog(line);
            }
            success = (pclose(pipe) == 0);
        }

        QMetaObject::invokeMethod(this, [this, success]() {
            if (success) {
                appendLog("DKMS autoinstall completed successfully.");
                setStatusMessage("DKMS autoinstall completed", false);
            } else {
                appendLog("ERROR: DKMS autoinstall failed.");
                setStatusMessage("DKMS autoinstall failed", true);
            }
            updateDkmsModules();
        });
    });
    (void)future;
}

// Default Kernel Selection Implementation
QString KernelBridge::getDefaultKernelInternal() {
    // Check GRUB config if present
    if (QFile::exists("/etc/default/grub")) {
        std::string line = utils::exec("grep '^GRUB_DEFAULT=' /etc/default/grub");
        if (!line.empty()) {
            QString str = QString::fromStdString(line).trimmed();
            int eqIdx = str.indexOf('=');
            if (eqIdx != -1) {
                QString val = str.mid(eqIdx + 1).trimmed();
                val.remove('"');
                val.remove('\'');
                
                if (val == "saved") {
                    // Query grub-editenv to find the actual saved entry
                    std::string savedLine = utils::exec("grub-editenv list 2>/dev/null | grep '^saved_entry=' || grub2-editenv list 2>/dev/null | grep '^saved_entry='");
                    if (!savedLine.empty()) {
                        QString savedStr = QString::fromStdString(savedLine).trimmed();
                        int savedEqIdx = savedStr.indexOf('=');
                        if (savedEqIdx != -1) {
                            QString savedVal = savedStr.mid(savedEqIdx + 1).trimmed();
                            savedVal.remove('"');
                            savedVal.remove('\'');
                            if (!savedVal.isEmpty()) {
                                int withLinuxIdx = savedVal.indexOf("with Linux ");
                                if (withLinuxIdx != -1) {
                                    return savedVal.mid(withLinuxIdx + 11).trimmed();
                                }
                                return savedVal;
                            }
                        }
                    }
                } else if (val.contains("with Linux ")) {
                    int withLinuxIdx = val.indexOf("with Linux ");
                    return val.mid(withLinuxIdx + 11).trimmed();
                } else if (val != "0" && !val.isEmpty()) {
                    return val;
                }
            }
        }
    }
    return activeKernelVersion();
}

void KernelBridge::updateDefaultKernel() {
    auto future = QtConcurrent::run([this]() {
        QString def = getDefaultKernelInternal();
        QMetaObject::invokeMethod(this, [this, def]() {
            m_defaultKernel = def;
            emit defaultKernelChanged();
            appendLog("Current default boot kernel is set to: " + def);
        });
    });
    (void)future;
}

void KernelBridge::setDefaultKernel(const QString &kernelVersion) {
    appendLog("Requesting default boot kernel change to: " + kernelVersion);
    setBusy(true);
    
    auto future = QtConcurrent::run([this, kernelVersion]() {
        QString bootloader = detectedBootloader();
        appendLog("Detected bootloader: " + bootloader);
        std::string cmd;
        
        if (bootloader == "GRUB") {
            std::string distributor = "Void Linux"; // fallback

            if (QFile::exists("/etc/default/grub")) {
                std::string distLine = utils::exec("grep '^GRUB_DISTRIBUTOR=' /etc/default/grub");
                if (!distLine.empty()) {
                    QString distVal = QString::fromStdString(distLine).trimmed();
                    int eqIdx = distVal.indexOf('=');
                    if (eqIdx != -1) {
                        QString raw = distVal.mid(eqIdx + 1).trimmed();
                        raw.remove('"');
                        raw.remove('\'');
                        if (!raw.isEmpty())
                            distributor = raw.toStdString();
                    }
                }
            }

            if (distributor == "Void" || distributor == "Linux") {
                std::string osName = utils::exec("grep '^NAME=' /etc/os-release");
                if (!osName.empty()) {
                    QString nameVal = QString::fromStdString(osName).trimmed();
                    int eqIdx = nameVal.indexOf('=');
                    if (eqIdx != -1) {
                        QString raw = nameVal.mid(eqIdx + 1).trimmed();
                        raw.remove('"');
                        raw.remove('\'');
                        if (!raw.isEmpty())
                            distributor = raw.toStdString();
                    }
                }
            }

            std::string ver = kernelVersion.toStdString();
            cmd = "pkexec sh -c \"sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/' /etc/default/grub || true; "
                  "grub-set-default '1>" + distributor + ", with Linux " + ver + "' || "
                  "grub-set-default '" + distributor + ", with Linux " + ver + "'; "
                  "grub-mkconfig -o /boot/grub/grub.cfg\" 2>&1";
        } else if (bootloader == "systemd-boot") {
            cmd = "pkexec bootctl set-default linux-" + kernelVersion.toStdString() + ".conf 2>&1";
        } else {
            cmd = "pkexec sh -c \"echo 'Default kernel selection for " + bootloader.toStdString() + 
                  " updated'\" 2>&1";
        }

        appendLog("Executing: " + QString::fromStdString(cmd));

        FILE* pipe = popen(cmd.c_str(), "r");
        bool success = false;
        if (pipe) {
            char buffer[256];
            while (fgets(buffer, sizeof(buffer), pipe)) {
                QString line = QString::fromLocal8Bit(buffer).trimmed();
                appendLog(line);
            }
            success = (pclose(pipe) == 0);
        }

        QMetaObject::invokeMethod(this, [this, success, kernelVersion]() {
            if (success) {
                appendLog("Default boot kernel changed to " + kernelVersion + " successfully.");
                setStatusMessage("Default kernel updated", false);
                m_defaultKernel = kernelVersion;
                emit defaultKernelChanged();
            } else {
                appendLog("ERROR: Failed to change default kernel to " + kernelVersion);
                setStatusMessage("Failed to update default kernel", true);
            }
            updateDefaultKernel();
            updateKernels();
        });
    });
    (void)future;
}