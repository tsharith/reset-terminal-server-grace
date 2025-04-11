# Reset-RDSGracePeriod.ps1

A PowerShell utility to **query** and **reset** the Remote Desktop Services (RDS) grace period on Windows Server.  
This tool resets the licensing grace period back to the default **120 days** by removing a specific registry key.

---

## 📌 Features

- Displays remaining RDS grace period days.
- Takes ownership of the required registry key.
- Resets the grace period by deleting the licensing key.
- Works on Windows Server environments running RDS/Terminal Services.

---

## ⚙️ Requirements

- Administrator privileges.
- PowerShell (tested on versions 5.1+).
- The server must have RDS/Terminal Services role installed.
- Optional: `tlsbln.exe` should be available on the system to refresh grace period display.

---

## 🚀 Usage

1. **Open PowerShell as Administrator**
2. **Run the script**:

```powershell
.\Reset-RDSGracePeriod.ps1

