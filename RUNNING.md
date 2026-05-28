# Homestay Booking API — Running Guide

## 🚀 Quick Start (Frontend Team)

### Option 1 — Double-click (easiest)
```
Double-click: start-api.cmd
```

### Option 2 — Terminal
```cmd
.\start-api.cmd
```

The script will:
1. Automatically detect and stop any old backend instance
2. Start the API on **http://localhost:8080**
3. Open Swagger in your browser

---

## 🌐 URLs

| Endpoint | URL |
|----------|-----|
| **Swagger UI** | http://localhost:8080/swagger |
| **Health Check** | http://localhost:8080/api/health |
| **API Base** | http://localhost:8080 |

---

## 🛑 Stop the API

### Option 1 — Press Ctrl+C in the terminal running the API

### Option 2 — Double-click stop script
```
Double-click: stop-api.cmd
```

### Option 3 — Terminal
```cmd
.\stop-api.cmd
```

---

## ⚠️ Important Rules

- **Do NOT open multiple `start-api.cmd` windows at the same time.**
- **Always use `start-api.cmd`** instead of `dotnet run` directly — the script handles port cleanup automatically.
- If Swagger doesn't open automatically, open your browser and go to: http://localhost:8080/swagger

---

## 📱 Flutter / Frontend Base URLs

| Platform | Base URL |
|----------|----------|
| Flutter Web / Desktop / Postman | `http://localhost:8080` |
| Flutter Android Emulator | `http://10.0.2.2:8080` |
| Real Android Device (same Wi-Fi) | `http://192.168.x.x:8080` *(use your laptop's LAN IP)* |

> To find your LAN IP: open cmd → type `ipconfig` → look for IPv4 Address under your Wi-Fi adapter.

---

## 🔧 Manual Port Cleanup (if needed)

If `start-api.cmd` fails to stop a stuck process, use these commands:

**Find process on port 8080:**
```cmd
netstat -ano | findstr :8080
```

**Kill it (replace `<PID>` with the number from above):**
```cmd
taskkill /PID <PID> /F
```

**PowerShell one-liner:**
```powershell
Get-NetTCPConnection -LocalPort 8080 -EA SilentlyContinue | % { Stop-Process -Id $_.OwningProcess -Force -EA SilentlyContinue }
```

---

## 🗄️ Database

The backend uses a local MySQL database. Make sure MySQL is running before starting the API.

Connection: `server=localhost;port=3306;database=homestay_booking;user=root;password=12345;`

---

## 📧 Email & Google Login (Optional)

To enable welcome emails and password reset:
1. Open `src/HomestayBooking.Api/appsettings.Development.json`
2. Fill in `Email.Username`, `Email.Password` (Gmail App Password), `Email.FromAddress`

To enable Google Login:
1. Fill in `GoogleAuth.ClientId`

> If these are left empty, the API still works — email features are silently skipped.
