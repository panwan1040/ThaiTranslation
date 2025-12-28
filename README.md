# 🎮 Shape of Dreams - Thai Translation Mod

## 📖 วิธีการแปลภาษา (สำหรับผู้ช่วยแปล)

### ไฟล์ CSV สำหรับแปล

ไฟล์ทั้งหมดอยู่ใน folder `translations/`:

| ไฟล์ | คำอธิบาย | จำนวน items |
|------|----------|-------------|
| `memories_full.csv` | ความทรงจำ/สกิล | ~128 รายการ |
| `essences_full.csv` | อัญมณี/แก่นสาร | ~100+ รายการ |
| `stars_full.csv` | ดาว (Star Tree) | ~100+ รายการ |
| `travelers_full.csv` | ตัวละคร | 9 รายการ |
| `achievements_full.csv` | ความสำเร็จ | ~60+ รายการ |

### คอลัมน์ที่ต้องแปล

ทุกไฟล์มีโครงสร้างเหมือนกัน:
- `*_EN` = ข้อความภาษาอังกฤษ (**อย่าแก้ไข**)
- `*_TH` = ช่องว่างสำหรับใส่คำแปลภาษาไทย (**แปลตรงนี้**)

ตัวอย่าง:
```
Key          | Name_EN    | Name_TH     | Desc_EN                  | Desc_TH
St_C_BackStep| Backstep   | ถอยฉากระเบิด | Leap backward and drop...| กระโดดถอยหลังแล้วทิ้ง...
```

### ⚠️ สิ่งสำคัญเมื่อแปล

1. **Rich Text Tags** - เก็บ tags ไว้ให้ครบ:
   - `<color=yellow>damage</color>` → `<color=yellow>ความเสียหาย</color>`
   - `<color=#16D7FF>180%</color>` → เก็บ tag ไว้รอบตัวเลข

2. **Placeholders {0}, {1}** - ใน `RawDesc_TH`:
   - เก็บ `{0}`, `{1}`, `{2}` ไว้ที่ตำแหน่งที่ถูกต้อง
   - ระบบจะแทนค่าตัวเลขให้อัตโนมัติ

3. **Newlines** - ใช้ `\n` สำหรับขึ้นบรรทัดใหม่

---

## 🛠️ วิธีใช้งาน Scripts

### 1. Extract ข้อมูลจากเกมเป็น CSV ใหม่
```powershell
.\master_extract_all.ps1
```
รันเมื่อ: เกมอัพเดทและมี content ใหม่

### 2. Merge คำแปลเดิมเข้ากับ CSV ใหม่
```powershell
.\merge_existing_translations.ps1
```
รันเมื่อ: หลัง extract และต้องการรวมคำแปลที่มีอยู่

### 3. Import CSV เป็น JSON สำหรับ Mod
```powershell
.\master_import_csv.ps1
```
รันเมื่อ: แปลเสร็จและต้องการใช้งานใน Mod

### 4. Build Mod DLL
```powershell
dotnet build ThaiTranslation.csproj -c Release
Copy-Item "bin\Release\netstandard2.1\ThaiTranslation.dll" -Destination "." -Force
```

---

## 📂 โครงสร้างไฟล์

```
ThaiTranslation/
├── ThaiTranslation.cs      # โค้หลักของ Mod
├── ThaiTranslation.dll     # Mod ที่ compile แล้ว
├── thaifont                # ฟอนต์ไทย
├── translations/           # CSV สำหรับแปล
│   ├── memories_full.csv
│   ├── essences_full.csv
│   ├── stars_full.csv
│   ├── travelers_full.csv
│   └── achievements_full.csv
├── RawData/th-TH/          # JSON ที่ Mod ใช้
│   ├── memories.json
│   ├── essences.json
│   ├── stars.json
│   ├── travelers.json
│   └── achievements.json
└── master_*.ps1            # Scripts ต่างๆ
```

---

## 🎯 Workflow สำหรับผู้แปล

1. **เปิด CSV** ด้วย Excel, Google Sheets, หรือ LibreOffice
2. **กรอกคำแปล** ในคอลัมน์ `*_TH`
3. **บันทึก** เป็น UTF-8 CSV
4. **รัน** `master_import_csv.ps1`
5. **ทดสอบ** ในเกม

---

## 📝 ฟีเจอร์ใหม่ใน Version 2.0

- ✅ รองรับ `rawDesc` + dynamic values
- ✅ แปล Stars (Star Tree)
- ✅ แปล Travelers (ตัวละคร)
- ✅ เก็บ Rich Text Tags ให้ครบ
- ✅ CSV format ที่ครบถ้วน

---

## 🙏 Credits

- Original Game: Shape of Dreams
- Thai Translation: [Your Name]
- Tools: Harmony, Unity TextMeshPro

---

*Last Updated: 2025-12-28*
