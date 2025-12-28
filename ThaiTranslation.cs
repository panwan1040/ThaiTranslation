using System;
using System.IO;
using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using System.Linq;
using UnityEngine;
using HarmonyLib;
using Newtonsoft.Json;
using TMPro;
using UnityEngine.TextCore;
using UnityEngine.TextCore.LowLevel;
using DewInternal;

namespace ThaiTranslation
{
    /// <summary>
    /// Thai Translation Mod for Shape of Dreams
    /// ม็อดแปลภาษาไทยสำหรับเกม Shape of Dreams
    /// </summary>
    public class ThaiTranslationMod : ModBehaviour
    {
        public static ThaiTranslationMod Instance { get; private set; }
        
        public static Dictionary<string, Dictionary<string, object>> ThaiTravelers = new Dictionary<string, Dictionary<string, object>>();
        public static Dictionary<string, Dictionary<string, object>> ThaiMemories = new Dictionary<string, Dictionary<string, object>>();
        public static Dictionary<string, Dictionary<string, object>> ThaiEssences = new Dictionary<string, Dictionary<string, object>>();
        public static Dictionary<string, Dictionary<string, object>> ThaiStars = new Dictionary<string, Dictionary<string, object>>();
        public static Dictionary<string, Dictionary<string, object>> ThaiAchievements = new Dictionary<string, Dictionary<string, object>>();
        public static Dictionary<string, string> ThaiUI = new Dictionary<string, string>();
        
        public static bool TranslationsLoaded = false;
        public static bool EnableThaiTranslation = true;
        public static bool DebugMode = true; // Set to true to log UI keys for translation
        
        private static HashSet<string> loggedKeys = new HashSet<string>();
        
        public static TMP_FontAsset ThaiFontAsset = null;
        public static Font ThaiFont = null;
        public static AssetBundle FontBundle = null;
        public static bool FontLoaded = false;
        
        private string modPath;
        
        // Thai Unicode range
        private static string ThaiCharacters = "กขฃคฅฆงจฉชซฌญฎฏฐฑฒณดตถทธนบปผฝพฟภมยรลวศษสหฬอฮฤฦะาำิีึืุูเแโใไๅๆ็่้๊๋์ํ๎๏๐๑๒๓๔๕๖๗๘๙";
        
        private void Awake()
        {
            Instance = this;
            modPath = mod.path;
            
            Debug.Log("[ThaiTranslation] ========================================");
            Debug.Log("[ThaiTranslation] Thai Translation Mod Loading...");
            Debug.Log("[ThaiTranslation] Mod Path: " + modPath);
            
            LoadTranslations();
            ApplyPatches();
            
            Debug.Log("[ThaiTranslation] Thai Translation Mod Loaded!");
            Debug.Log("[ThaiTranslation] ========================================");
        }
        
        private void Start()
        {
            StartCoroutine(SetupFontCoroutine());
        }
        
        private IEnumerator SetupFontCoroutine()
        {
            // Wait for game initialization
            yield return new WaitForSeconds(0.5f);
            
            // Load Thai font from AssetBundle
            LoadThaiFontFromAssetBundle();
            
            // Retry if failed
            if (!FontLoaded)
            {
                yield return new WaitForSeconds(2f);
                LoadThaiFontFromAssetBundle();
            }
        }
        
        private void LoadThaiFontFromAssetBundle()
        {
            if (FontLoaded) return;
            
            try
            {
                string bundlePath = Path.Combine(modPath, "thaifont");
                Debug.Log("[ThaiTranslation] Loading AssetBundle from: " + bundlePath);
                
                if (!File.Exists(bundlePath))
                {
                    Debug.LogError("[ThaiTranslation] AssetBundle not found: " + bundlePath);
                    return;
                }
                
                // Load AssetBundle
                FontBundle = AssetBundle.LoadFromFile(bundlePath);
                if (FontBundle == null)
                {
                    Debug.LogError("[ThaiTranslation] Failed to load AssetBundle");
                    return;
                }
                
                Debug.Log("[ThaiTranslation] AssetBundle loaded successfully");
                
                // List all assets in bundle for debugging
                string[] assetNames = FontBundle.GetAllAssetNames();
                Debug.Log("[ThaiTranslation] Assets in bundle: " + assetNames.Length);
                foreach (string name in assetNames)
                {
                    Debug.Log("[ThaiTranslation]   - " + name);
                }
                
                // Load Font from bundle
                ThaiFont = FontBundle.LoadAsset<Font>("Prompt-Regular");
                
                if (ThaiFont == null)
                {
                    // Try lowercase
                    ThaiFont = FontBundle.LoadAsset<Font>("prompt-regular");
                }
                
                if (ThaiFont == null)
                {
                    // Try with extension
                    ThaiFont = FontBundle.LoadAsset<Font>("Prompt-Regular.ttf");
                }
                
                if (ThaiFont == null)
                {
                    // Try loading first font found
                    Font[] allFonts = FontBundle.LoadAllAssets<Font>();
                    if (allFonts.Length > 0)
                    {
                        ThaiFont = allFonts[0];
                        Debug.Log("[ThaiTranslation] Loaded font: " + ThaiFont.name);
                    }
                }
                
                if (ThaiFont == null)
                {
                    Debug.LogError("[ThaiTranslation] Failed to load Font from AssetBundle");
                    Debug.LogError("[ThaiTranslation] Available asset names:");
                    foreach (string name in assetNames)
                    {
                        Debug.LogError("  " + name);
                    }
                    return;
                }
                
                Debug.Log("[ThaiTranslation] Font loaded: " + ThaiFont.name);
                
                // Create TMP_FontAsset from Font
                CreateTMPFontAsset();
                
            }
            catch (Exception ex)
            {
                Debug.LogError("[ThaiTranslation] LoadThaiFontFromAssetBundle error: " + ex.Message);
                Debug.LogError(ex.StackTrace);
            }
        }
        
        private void CreateTMPFontAsset()
        {
            if (ThaiFont == null) return;
            
            try
            {
                Debug.Log("[ThaiTranslation] Creating TMP_FontAsset from font...");
                
                // Use parameterized CreateFontAsset with correct settings to prevent stretching
                // Simple CreateFontAsset uses default values that may cause stretching issues
                try
                {
                    // Optimal settings for Thai font to prevent stretching:
                    // - Sampling size 44: Standard TMP size, prevents vertical stretching
                    // - Padding 5: Adequate for SDF rendering
                    // - Atlas 2048x2048: Large enough for all Thai characters with good quality
                    ThaiFontAsset = TMP_FontAsset.CreateFontAsset(
                        ThaiFont,
                        44,   // Sampling size (standard size, prevents stretching)
                        5,    // Padding
                        GlyphRenderMode.SDFAA,
                        2048, // Atlas width
                        2048  // Atlas height
                    );
                    Debug.Log("[ThaiTranslation] Created TMP_FontAsset with optimized settings");
                }
                catch (Exception ex1)
                {
                    Debug.Log("[ThaiTranslation] Parameterized CreateFontAsset failed: " + ex1.Message);
                    
                    // Fallback to simple version as last resort
                    try
                    {
                        ThaiFontAsset = TMP_FontAsset.CreateFontAsset(ThaiFont);
                        Debug.Log("[ThaiTranslation] Using simple CreateFontAsset (may have stretching issues)");
                    }
                    catch (Exception ex2)
                    {
                        Debug.LogError("[ThaiTranslation] All CreateFontAsset attempts failed: " + ex2.Message);
                    }
                }
                
                if (ThaiFontAsset == null)
                {
                    Debug.LogError("[ThaiTranslation] Failed to create TMP_FontAsset");
                    return;
                }
                
                ThaiFontAsset.name = "Prompt-Thai-SDF";
                Debug.Log("[ThaiTranslation] TMP_FontAsset created: " + ThaiFontAsset.name);
                
                // Adjust font metrics to match game fonts and prevent stretching
                AdjustFontMetrics();
                
                // Add Thai characters to the font atlas
                string missingChars;
                bool addResult = ThaiFontAsset.TryAddCharacters(ThaiCharacters, out missingChars);
                
                if (addResult)
                {
                    Debug.Log("[ThaiTranslation] All Thai characters added successfully!");
                }
                else
                {
                    int missing = missingChars != null ? missingChars.Length : 0;
                    Debug.Log("[ThaiTranslation] Thai characters added. Missing: " + missing);
                }
                
                // Add fallback to all game fonts
                AttachFallbackToAllFonts();
                
                FontLoaded = true;
                Debug.Log("[ThaiTranslation] Thai font setup complete!");
                
            }
            catch (Exception ex)
            {
                Debug.LogError("[ThaiTranslation] CreateTMPFontAsset error: " + ex.Message);
                Debug.LogError(ex.StackTrace);
            }
        }
        
        private void AdjustFontMetrics()
        {
            if (ThaiFontAsset == null) return;
            
            try
            {
                // Find a game font to match metrics with
                TMP_FontAsset[] gameFonts = Resources.FindObjectsOfTypeAll<TMP_FontAsset>();
                TMP_FontAsset referenceFont = null;
                
                foreach (TMP_FontAsset font in gameFonts)
                {
                    if (font == null || font == ThaiFontAsset) continue;
                    if (font.name.Contains("Prompt") || font.name.Contains("Thai")) continue;
                    
                    // Prefer fonts that look like main game fonts
                    if (font.name.Contains("SDF") || font.name.Contains("Bold") || font.name.Contains("Regular"))
                    {
                        referenceFont = font;
                        break;
                    }
                    
                    // Take any valid font as fallback reference
                    if (referenceFont == null)
                    {
                        referenceFont = font;
                    }
                }
                
                if (referenceFont != null)
                {
                    Debug.Log("[ThaiTranslation] Adjusting metrics to match: " + referenceFont.name);
                    
                    // Get current face info
                    FaceInfo thaiFaceInfo = ThaiFontAsset.faceInfo;
                    FaceInfo refFaceInfo = referenceFont.faceInfo;
                    
                    // Calculate scale ratio to match game font
                    float scaleRatio = 1.0f;
                    if (thaiFaceInfo.pointSize > 0 && refFaceInfo.pointSize > 0)
                    {
                        scaleRatio = (float)refFaceInfo.pointSize / (float)thaiFaceInfo.pointSize;
                    }
                    
                    // Adjust Thai font metrics to match reference
                    thaiFaceInfo.scale = refFaceInfo.scale;
                    thaiFaceInfo.lineHeight = refFaceInfo.lineHeight;
                    
                    // Apply adjusted metrics
                    ThaiFontAsset.faceInfo = thaiFaceInfo;
                    
                    Debug.Log("[ThaiTranslation] Font metrics adjusted. Scale: " + thaiFaceInfo.scale + 
                              ", LineHeight: " + thaiFaceInfo.lineHeight);
                }
                else
                {
                    Debug.Log("[ThaiTranslation] No reference font found, using default metrics");
                }
            }
            catch (Exception ex)
            {
                Debug.Log("[ThaiTranslation] AdjustFontMetrics error: " + ex.Message);
            }
        }
        
        private void AttachFallbackToAllFonts()
        {
            if (ThaiFontAsset == null)
            {
                Debug.LogError("[ThaiTranslation] Cannot attach fallback - ThaiFontAsset is null");
                return;
            }
            
            try
            {
                // Find all TMP fonts in the game
                TMP_FontAsset[] allFonts = Resources.FindObjectsOfTypeAll<TMP_FontAsset>();
                int attached = 0;
                
                Debug.Log("[ThaiTranslation] Found " + allFonts.Length + " TMP fonts in game");
                
                foreach (TMP_FontAsset font in allFonts)
                {
                    if (font == null) continue;
                    if (font == ThaiFontAsset) continue;
                    if (font.name.Contains("Prompt") || font.name.Contains("Thai")) continue;
                    
                    try
                    {
                        if (font.fallbackFontAssetTable == null)
                        {
                            font.fallbackFontAssetTable = new List<TMP_FontAsset>();
                        }
                        
                        if (!font.fallbackFontAssetTable.Contains(ThaiFontAsset))
                        {
                            // Add at beginning for priority
                            font.fallbackFontAssetTable.Insert(0, ThaiFontAsset);
                            attached++;
                            Debug.Log("[ThaiTranslation] Added fallback to: " + font.name);
                        }
                    }
                    catch (Exception ex)
                    {
                        Debug.Log("[ThaiTranslation] Error adding fallback to " + font.name + ": " + ex.Message);
                    }
                }
                
                Debug.Log("[ThaiTranslation] Attached Thai font as fallback to " + attached + " fonts");
                
                // Also try TMP_Settings global fallback
                try
                {
                    List<TMP_FontAsset> globalFallback = TMP_Settings.fallbackFontAssets;
                    if (globalFallback != null && !globalFallback.Contains(ThaiFontAsset))
                    {
                        globalFallback.Insert(0, ThaiFontAsset);
                        Debug.Log("[ThaiTranslation] Added to TMP global fallback list");
                    }
                }
                catch (Exception ex)
                {
                    Debug.Log("[ThaiTranslation] Could not add to global fallback: " + ex.Message);
                }
            }
            catch (Exception ex)
            {
                Debug.LogError("[ThaiTranslation] AttachFallbackToAllFonts error: " + ex.Message);
            }
        }
        
        private void LoadTranslations()
        {
            try
            {
                string rawDataPath = Path.Combine(modPath, "RawData", "th-TH");
                
                if (!Directory.Exists(rawDataPath))
                {
                    Debug.LogWarning("[ThaiTranslation] Thai data folder not found: " + rawDataPath);
                    return;
                }
                
                LoadJsonFile(Path.Combine(rawDataPath, "travelers.json"), ref ThaiTravelers, "Travelers");
                LoadJsonFile(Path.Combine(rawDataPath, "memories.json"), ref ThaiMemories, "Memories");
                LoadJsonFile(Path.Combine(rawDataPath, "essences.json"), ref ThaiEssences, "Essences");
                LoadJsonFile(Path.Combine(rawDataPath, "stars.json"), ref ThaiStars, "Stars");
                LoadJsonFile(Path.Combine(rawDataPath, "achievements.json"), ref ThaiAchievements, "Achievements");
                
                string uiPath = Path.Combine(rawDataPath, "ui.json");
                if (File.Exists(uiPath))
                {
                    string json = File.ReadAllText(uiPath, System.Text.Encoding.UTF8);
                    ThaiUI = JsonConvert.DeserializeObject<Dictionary<string, string>>(json);
                    if (ThaiUI == null) ThaiUI = new Dictionary<string, string>();
                    Debug.Log("[ThaiTranslation] Loaded UI: " + ThaiUI.Count + " entries");
                }
                
                TranslationsLoaded = true;
                Debug.Log("[ThaiTranslation] All translations loaded!");
            }
            catch (Exception ex)
            {
                Debug.LogError("[ThaiTranslation] LoadTranslations error: " + ex.Message);
            }
        }
        
        private void LoadJsonFile(string path, ref Dictionary<string, Dictionary<string, object>> dict, string name)
        {
            if (File.Exists(path))
            {
                string json = File.ReadAllText(path, System.Text.Encoding.UTF8);
                dict = JsonConvert.DeserializeObject<Dictionary<string, Dictionary<string, object>>>(json);
                if (dict == null) dict = new Dictionary<string, Dictionary<string, object>>();
                Debug.Log("[ThaiTranslation] Loaded " + name + ": " + dict.Count + " entries");
            }
        }
        
        private void ApplyPatches()
        {
            try
            {
                // Log all available methods in DewLocalization for debugging
                Debug.Log("[ThaiTranslation] === Listing DewLocalization methods ===");
                Type dewLocType = typeof(DewLocalization);
                var methods = dewLocType.GetMethods(BindingFlags.Public | BindingFlags.Static | BindingFlags.Instance);
                foreach (var method in methods)
                {
                    string paramList = string.Join(", ", method.GetParameters().Select(p => p.ParameterType.Name + " " + p.Name));
                    if (method.Name.Contains("Skill") || method.Name.Contains("Memory") || method.Name.Contains("Gem") || method.Name.Contains("Description"))
                    {
                        Debug.Log("[ThaiTranslation] Method: " + method.Name + "(" + paramList + ") -> " + method.ReturnType.Name);
                    }
                }
                Debug.Log("[ThaiTranslation] === End of DewLocalization methods ===");
                
                harmony.PatchAll(Assembly.GetExecutingAssembly());
                Debug.Log("[ThaiTranslation] Harmony patches applied!");
                
                // Log patch results
                var patchedMethods = Harmony.GetAllPatchedMethods();
                Debug.Log("[ThaiTranslation] === Patched methods ===");
                foreach (var patchedMethod in patchedMethods)
                {
                    var patchInfo = Harmony.GetPatchInfo(patchedMethod);
                    if (patchInfo.Owners.Contains(harmony.Id))
                    {
                        Debug.Log("[ThaiTranslation] Patched: " + patchedMethod.DeclaringType.Name + "." + patchedMethod.Name);
                    }
                }
                Debug.Log("[ThaiTranslation] === End of patched methods ===");
            }
            catch (Exception ex)
            {
                Debug.LogError("[ThaiTranslation] ApplyPatches error: " + ex.Message + "\n" + ex.StackTrace);
            }
        }
        
        private void OnDestroy()
        {
            Debug.Log("[ThaiTranslation] Unloading mod...");
            
            harmony.UnpatchAll(mod.metadata.id);
            
            // Unload AssetBundle
            if (FontBundle != null)
            {
                FontBundle.Unload(true);
                FontBundle = null;
            }
            
            TranslationsLoaded = false;
            FontLoaded = false;
            Instance = null;
        }
        
        // ========== Translation Helper Methods ==========
        
        public static string GetTranslation(Dictionary<string, Dictionary<string, object>> dict, string key, string field)
        {
            if (!TranslationsLoaded || !EnableThaiTranslation) return null;
            
            Dictionary<string, object> entry;
            if (dict.TryGetValue(key, out entry))
            {
                object value;
                if (entry.TryGetValue(field, out value))
                {
                    return value != null ? value.ToString() : null;
                }
            }
            return null;
        }
        
        public static string GetMemoryName(string key) { return GetTranslation(ThaiMemories, key, "name"); }
        public static string GetMemoryShortDescription(string key) { return GetTranslation(ThaiMemories, key, "shortDescription"); }
        public static string GetMemoryDescription(string key) { return WrapText(GetTranslation(ThaiMemories, key, "description")); }
        public static string GetMemoryLore(string key) { return WrapText(GetTranslation(ThaiMemories, key, "lore")); }
        public static string GetEssenceName(string key) 
        { 
            // Game sends key like "C_Void" but JSON has "Gem_C_Void"
            string fullKey = key.StartsWith("Gem_") ? key : "Gem_" + key;
            return GetTranslation(ThaiEssences, fullKey, "name"); 
        }
        public static string GetEssenceDescription(string key) 
        { 
            string fullKey = key.StartsWith("Gem_") ? key : "Gem_" + key;
            return WrapText(GetTranslation(ThaiEssences, fullKey, "description")); 
        }
        public static string GetStarName(string key) { return GetTranslation(ThaiStars, key, "name"); }
        public static string GetStarDescription(string key) { return WrapText(GetTranslation(ThaiStars, key, "description")); }
        public static string GetStarRawDesc(string key) { return GetTranslation(ThaiStars, key, "rawDesc"); }
        public static string GetStarLore(string key) { return WrapText(GetTranslation(ThaiStars, key, "lore")); }
        public static string GetAchievementName(string key) { return GetTranslation(ThaiAchievements, key, "name"); }
        public static string GetAchievementDescription(string key) { return WrapText(GetTranslation(ThaiAchievements, key, "description")); }
        
        // Traveler translations
        public static string GetTravelerName(string key) { return GetTranslation(ThaiTravelers, key, "name"); }
        public static string GetTravelerSubtitle(string key) { return GetTranslation(ThaiTravelers, key, "subtitle"); }
        public static string GetTravelerDescription(string key) { return WrapText(GetTranslation(ThaiTravelers, key, "description")); }
        
        // RawDesc with placeholders for dynamic values
        public static string GetMemoryRawDesc(string key) { return GetTranslation(ThaiMemories, key, "rawDesc"); }
        public static string GetEssenceRawDesc(string key) 
        { 
            string fullKey = key.StartsWith("Gem_") ? key : "Gem_" + key;
            return GetTranslation(ThaiEssences, fullKey, "rawDesc"); 
        }
        
        // Wrap text to MAX_LINE_LENGTH characters per line to prevent text stretching
        private const int MAX_LINE_LENGTH = 55;
        
        // Characters that are good break points for Thai text
        private static readonly char[] ThaiBreakChars = new char[] { ' ', ',', '.', '/', ')', '(', '>', '<', '!', '?', ':', ';', '"', '\'', '–', '-', '—', '「', '」', '…' };
        
        public static string WrapText(string text)
        {
            if (string.IsNullOrEmpty(text)) return text;
            if (text.Length <= MAX_LINE_LENGTH) return text; // Optimization for short text

            try
            {
                System.Text.StringBuilder result = new System.Text.StringBuilder();
                int currentLineLength = 0;
                bool insideTag = false;
                
                string[] words = SplitTextPreservingTags(text);
                
                foreach (string word in words)
                {
                    // Check if this word is a tag
                    bool isTag = word.StartsWith("<") && word.EndsWith(">");
                    int wordLength = isTag ? 0 : word.Length; // Tags have 0 visual length for wrapping calculation
                    
                    // If adding this word exceeds max length, and it's not a tag (unless line is extremely long)
                    if (currentLineLength + wordLength > MAX_LINE_LENGTH && currentLineLength > 0)
                    {
                        result.Append('\n');
                        currentLineLength = 0;
                    }
                    
                    result.Append(word);
                    currentLineLength += wordLength;
                }
                
                string finalResult = result.ToString();
                
                // Debug log if wrapping rich text
                if (text.Contains("<color") && !finalResult.Contains("<color"))
                {
                     Debug.LogWarning("[ThaiTranslation] WrapText STRIPPED TAGS! Input: " + text + " Output: " + finalResult);
                }
                
                return finalResult;
            }
            catch (Exception ex)
            {
                Debug.Log("[ThaiTranslation] WrapText error: " + ex.Message);
                return text;
            }
        }

        // Helper to split text into words but keep tags as single units
        private static string[] SplitTextPreservingTags(string text)
        {
            List<string> units = new List<string>();
            System.Text.StringBuilder currentUnit = new System.Text.StringBuilder();
            bool insideTag = false;
            
            for (int i = 0; i < text.Length; i++)
            {
                char c = text[i];
                
                if (c == '<')
                {
                    // Start of tag
                    if (currentUnit.Length > 0 && !insideTag)
                    {
                        units.Add(currentUnit.ToString());
                        currentUnit.Clear();
                    }
                    insideTag = true;
                    currentUnit.Append(c);
                }
                else if (c == '>')
                {
                    // End of tag
                    currentUnit.Append(c);
                    if (insideTag)
                    {
                        units.Add(currentUnit.ToString());
                        currentUnit.Clear();
                        insideTag = false;
                    }
                }
                else if (!insideTag && Array.IndexOf(ThaiBreakChars, c) >= 0)
                {
                    // Break character outside tag
                    currentUnit.Append(c);
                    units.Add(currentUnit.ToString());
                    currentUnit.Clear();
                }
                else
                {
                    currentUnit.Append(c);
                }
            }
            
            if (currentUnit.Length > 0)
            {
                units.Add(currentUnit.ToString());
            }
            
            return units.ToArray();
        }

        
        public static string GetUIValue(string key)
        {
            if (!TranslationsLoaded || !EnableThaiTranslation) return null;
            string value;
            if (ThaiUI.TryGetValue(key, out value)) return value;
            return null;
        }
        
        public static void LogKey(string category, string key, string result)
        {
            if (!DebugMode) return;
            string logKey = category + ":" + key;
            if (!loggedKeys.Contains(logKey))
            {
                loggedKeys.Add(logKey);
                Debug.Log("[ThaiTranslation] [" + category + "] " + key + " -> " + (result != null ? "FOUND" : "MISSING"));
            }
        }
    }
    
    // ========== Harmony Patches ==========
    
    [HarmonyPatch]
    public static class DewLocalizationPatches
    {
        [HarmonyPatch(typeof(DewLocalization), "GetSkillName", new Type[] { typeof(string), typeof(int) })]
        [HarmonyPostfix]
        public static void GetSkillName_Postfix(string key, ref string __result)
        {
            try 
            { 
                // Try original key first
                string thai = ThaiTranslationMod.GetMemoryName(key);
                
                // If not found, try with St_ prefix (some memories use this prefix in data files)
                if (string.IsNullOrEmpty(thai))
                {
                    thai = ThaiTranslationMod.GetMemoryName("St_" + key);
                }
                
                if (!string.IsNullOrEmpty(thai)) 
                {
                    Debug.Log("[ThaiTranslation] GetSkillName: " + key + " -> " + thai);
                    __result = thai; 
                }
            } 
            catch (Exception ex) { Debug.Log("[ThaiTranslation] GetSkillName error: " + ex.Message); }
        }
        
        [HarmonyPatch(typeof(DewLocalization), "GetSkillShortDesc", new Type[] { typeof(string), typeof(int) })]
        [HarmonyPostfix]
        public static void GetSkillShortDesc_Postfix(string key, int configIndex, ref string __result)
        {
            try 
            { 
                Debug.Log("[ThaiTranslation] GetSkillShortDesc called! key: " + key);
                string thai = ThaiTranslationMod.GetMemoryShortDescription(key);
                if (string.IsNullOrEmpty(thai))
                {
                    thai = ThaiTranslationMod.GetMemoryShortDescription("St_" + key);
                }
                if (!string.IsNullOrEmpty(thai))
                {
                    Debug.Log("[ThaiTranslation] GetSkillShortDesc FOUND: " + thai);
                    __result = thai; 
                }
            } 
            catch (Exception ex) { Debug.Log("[ThaiTranslation] GetSkillShortDesc error: " + ex.Message); }
        }
        
        [HarmonyPatch(typeof(DewLocalization), "GetSkillDescription", new Type[] { typeof(string), typeof(int) })]
        [HarmonyPostfix]
        public static void GetSkillDescription_Postfix(string key, int configIndex, ref List<LocaleNode> __result)
        {
            try 
            { 
                Debug.Log("[ThaiTranslation] GetSkillDescription called! key: " + key);
                
                // Get Thai rawDesc (with placeholders like {0}, {1})
                string thaiRawDesc = ThaiTranslationMod.GetTranslation(ThaiTranslationMod.ThaiMemories, key, "rawDesc");
                if (string.IsNullOrEmpty(thaiRawDesc))
                {
                    thaiRawDesc = ThaiTranslationMod.GetTranslation(ThaiTranslationMod.ThaiMemories, "St_" + key, "rawDesc");
                }
                
                if (!string.IsNullOrEmpty(thaiRawDesc) && __result != null)
                {
                    Debug.Log("[ThaiTranslation] GetSkillDescription replacing text nodes with Thai rawDesc");
                    // Replace the text content in nodes, preserving structure (important for Alt key parsing)
                    foreach (var node in __result)
                    {
                        if (node.type == LocaleNodeType.Text && !string.IsNullOrEmpty(node.textData))
                        {
                            // Replace English text with Thai
                            node.textData = thaiRawDesc;
                            thaiRawDesc = ""; // Only replace first text node
                        }
                    }
                }
                else
                {
                    Debug.Log("[ThaiTranslation] GetSkillDescription - No Thai rawDesc found for: " + key);
                }
            } 
            catch (Exception ex) { Debug.Log("[ThaiTranslation] GetSkillDescription error: " + ex.Message); }
        }
        
        [HarmonyPatch(typeof(DewLocalization), "GetSkillMemory")]
        [HarmonyPostfix]
        public static void GetSkillMemory_Postfix(string key, ref string __result)
        {
            try 
            { 
                Debug.Log("[ThaiTranslation] GetSkillMemory (Lore) called! key: " + key);
                string thai = ThaiTranslationMod.GetMemoryLore(key);
                if (string.IsNullOrEmpty(thai))
                {
                    thai = ThaiTranslationMod.GetMemoryLore("St_" + key);
                }
                if (!string.IsNullOrEmpty(thai)) 
                {
                    Debug.Log("[ThaiTranslation] GetSkillMemory FOUND lore for: " + key);
                    __result = thai;
                }
                else
                {
                    Debug.Log("[ThaiTranslation] GetSkillMemory lore NOT FOUND for: " + key);
                }
            } 
            catch (Exception ex) { Debug.Log("[ThaiTranslation] GetSkillMemory error: " + ex.Message); }
        }
        
        [HarmonyPatch(typeof(DewLocalization), "GetGemName", new Type[] { typeof(string) })]
        [HarmonyPostfix]
        public static void GetGemName_Postfix(string key, ref string __result)
        {
            try 
            { 
                string thai = ThaiTranslationMod.GetEssenceName(key); 
                Debug.Log("[ThaiTranslation] GetGemName called! key: " + key + " -> " + (thai != null ? "FOUND: " + thai : "NOT FOUND"));
                if (!string.IsNullOrEmpty(thai)) 
                {
                    Debug.Log("[ThaiTranslation] Replacing gem name from: " + __result + " to: " + thai);
                    __result = thai; 
                }
            } 
            catch (Exception ex) { Debug.Log("[ThaiTranslation] GetGemName error: " + ex.Message); }
        }
        
        [HarmonyPatch(typeof(DewLocalization), "GetGemDescription", new Type[] { typeof(string) })]
        [HarmonyPrefix]
        public static bool GetGemDescription_Prefix(string key, ref IReadOnlyList<LocaleNode> __result)
        {
            try 
            { 
                string thai = ThaiTranslationMod.GetEssenceDescription(key); 
                if (!string.IsNullOrEmpty(thai)) 
                {
                    Debug.Log("[ThaiTranslation] GetGemDescription replacing for key: " + key);
                    List<LocaleNode> newList = new List<LocaleNode>();
                    LocaleNode node = new LocaleNode();
                    node.type = LocaleNodeType.Text;
                    node.textData = thai;
                    newList.Add(node);
                    __result = newList;
                    return false; // Skip original method
                }
            } 
            catch (Exception ex) { Debug.Log("[ThaiTranslation] GetGemDescription error: " + ex.Message); }
            return true; // Run original method if no translation found
        }
        
        [HarmonyPatch(typeof(DewLocalization), "GetStarName", new Type[] { typeof(string) })]
        [HarmonyPostfix]
        public static void GetStarName_Postfix(string key, ref string __result)
        {
            try { string thai = ThaiTranslationMod.GetStarName(key); if (!string.IsNullOrEmpty(thai)) __result = thai; } catch { }
        }
        
        [HarmonyPatch(typeof(DewLocalization), "GetStarLore")]
        [HarmonyPostfix]
        public static void GetStarLore_Postfix(string key, ref string __result)
        {
            try { string thai = ThaiTranslationMod.GetTranslation(ThaiTranslationMod.ThaiStars, key, "lore"); if (!string.IsNullOrEmpty(thai)) __result = thai; } catch { }
        }
        
        [HarmonyPatch(typeof(DewLocalization), "GetAchievementName")]
        [HarmonyPostfix]
        public static void GetAchievementName_Postfix(string key, ref string __result)
        {
            try { string thai = ThaiTranslationMod.GetAchievementName(key); if (!string.IsNullOrEmpty(thai)) __result = thai; } catch { }
        }
        
        // Note: GetStarDescription may not exist or have different signature
        // Stars use GetSkillDescription instead
        
        [HarmonyPatch(typeof(DewLocalization), "GetAchievementDescription")]
        [HarmonyPostfix]
        public static void GetAchievementDescription_Postfix(string key, ref string __result)
        {
            try { string thai = ThaiTranslationMod.GetAchievementDescription(key); if (!string.IsNullOrEmpty(thai)) __result = thai; } catch { }
        }
        
        [HarmonyPatch(typeof(DewLocalization), "GetUIValue")]
        [HarmonyPostfix]
        public static void GetUIValue_Postfix(string key, ref string __result)
        {
            try { 
                string thai = ThaiTranslationMod.GetUIValue(key); 
                ThaiTranslationMod.LogKey("UI", key, thai);
                if (!string.IsNullOrEmpty(thai)) __result = thai; 
            } catch { }
        }
        
        [HarmonyPatch(typeof(DewLocalization), "TryGetUIValue")]
        [HarmonyPostfix]
        public static void TryGetUIValue_Postfix(string key, ref string value, ref bool __result)
        {
            try { string thai = ThaiTranslationMod.GetUIValue(key); if (!string.IsNullOrEmpty(thai)) { value = thai; __result = true; } } catch { }
        }
        
        // Note: Hero/Traveler methods like GetHeroName, GetHeroSubtitle, GetHeroDescription
        // may not exist in DewLocalization. Will need to investigate the actual game API.
    }
}
