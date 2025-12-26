# Thai Translation Mod for Shape of Dreams
# ม็อดแปลภาษาไทยสำหรับเกม Shape of Dreams

![Status](https://img.shields.io/badge/Status-Translation%20Ready-green)
![Font](https://img.shields.io/badge/Font-Waiting%20Developer%20Support-yellow)

## 📝 Description / คำอธิบาย

This mod translates Shape of Dreams into Thai language. 

ม็อดนี้แปลเกม Shape of Dreams เป็นภาษาไทย

### ✅ What's Translated / สิ่งที่แปลแล้ว

| Category | Status |
|----------|--------|
| Travelers (ตัวละคร) | ✅ Complete |
| Memories/Skills (ความทรงจำ) | ✅ Complete |
| Stars (ดวงดาว) | ✅ Complete |
| Essences/Gems (หินแก่น) | ✅ Complete |
| Achievements (ความสำเร็จ) | ✅ Complete |
| UI Elements | ✅ Partial |

## ⚠️ Current Status / สถานะปัจจุบัน

**The translation works, but Thai characters cannot be displayed.**

การแปลทำงานได้แล้ว แต่ตัวอักษรไทยยังแสดงผลไม่ได้

### Why? / ทำไม?

The game's TextMeshPro fonts do not include Thai glyphs (Unicode U+0E00-0E7F). 
This is a technical limitation that requires the game developer to add Thai font support.

Font ของเกมไม่มี glyphs สำหรับภาษาไทย ต้องรอให้ผู้พัฒนาเกมเพิ่ม Thai font support

## 🙏 How You Can Help / คุณช่วยได้อย่างไร

Please request Thai font support from the developers:

1. **Steam Discussion**: https://steamcommunity.com/app/2809270/discussions/
2. **Discord**: Join LizardSmoothie's Discord and request Thai font support

กรุณาช่วย request ให้ผู้พัฒนาเพิ่ม Thai font:
- ไปที่ Steam Discussion หรือ Discord
- บอกว่ามี Thai translation mod พร้อมแล้ว แค่รอ font support

## 📦 Installation / การติดตั้ง

1. Download and extract the mod
2. Place the `ThaiTranslation` folder in:
   ```
   [Steam]\steamapps\common\Shape of Dreams\Mods\
   ```
3. Enable the mod in-game from the Mods menu
4. Wait for Thai font support from developer

## 📁 File Structure / โครงสร้างไฟล์

```
ThaiTranslation/
├── about/
│   ├── metadata.json      # Mod metadata
│   └── description.txt    # Description
├── RawData/
│   └── th-TH/
│       ├── travelers.json # Character translations
│       ├── memories.json  # Skill translations
│       ├── essences.json  # Gem translations
│       ├── stars.json     # Star translations
│       ├── achievements.json # Achievement translations
│       └── ui.json        # UI translations
├── Fonts/
│   └── Prompt/            # Thai font (Prompt) - OFL License
├── ThaiTranslation.dll    # Compiled mod
└── README.md              # This file
```

## 🔤 Included Font / Font ที่รวมมาด้วย

The mod includes **Prompt** font (Thai + Latin) under SIL Open Font License.
- Website: https://fonts.google.com/specimen/Prompt
- License: SIL Open Font License 1.1

## 📜 License / ลิขสิทธิ์

- **Mod Code**: MIT License
- **Translations**: Creative Commons Attribution 4.0
- **Prompt Font**: SIL Open Font License 1.1

## 👥 Credits / เครดิต

- **Translation**: Thai Modding Community
- **Font**: Cadson Demak (Prompt font)
- **Game**: LizardSmoothie (Shape of Dreams)

## 📞 Contact / ติดต่อ

If you want to help improve translations or have any questions:
- Create an issue on this repository
- Contact via Steam Discussion

---

**หมายเหตุ**: เมื่อผู้พัฒนาเกมเพิ่ม Thai font support แล้ว ม็อดนี้จะทำงานได้ทันที!
