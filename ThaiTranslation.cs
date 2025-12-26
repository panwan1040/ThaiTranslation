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
        public static bool DebugMode = false; // Set to true to log UI keys for translation
        
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
                harmony.PatchAll(Assembly.GetExecutingAssembly());
                Debug.Log("[ThaiTranslation] Harmony patches applied!");
            }
            catch (Exception ex)
            {
                Debug.LogError("[ThaiTranslation] ApplyPatches error: " + ex.Message);
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
        public static string GetEssenceName(string key) { return GetTranslation(ThaiEssences, key, "name"); }
        public static string GetEssenceDescription(string key) { return WrapText(GetTranslation(ThaiEssences, key, "description")); }
        public static string GetStarName(string key) { return GetTranslation(ThaiStars, key, "name"); }
        public static string GetStarDescription(string key) { return WrapText(GetTranslation(ThaiStars, key, "description")); }
        public static string GetStarLore(string key) { return WrapText(GetTranslation(ThaiStars, key, "lore")); }
        public static string GetAchievementName(string key) { return GetTranslation(ThaiAchievements, key, "name"); }
        public static string GetAchievementDescription(string key) { return WrapText(GetTranslation(ThaiAchievements, key, "description")); }
        
        // Wrap text to MAX_LINE_LENGTH characters per line to prevent text stretching
        private const int MAX_LINE_LENGTH = 55;
        
        // Characters that are good break points for Thai text
        private static readonly char[] ThaiBreakChars = new char[] { ' ', ',', '.', '/', ')', '(', '>', '<', '!', '?', ':', ';', '"', '\'', '–', '-', '—', '「', '」', '…' };
        
        public static string WrapText(string text)
        {
            if (string.IsNullOrEmpty(text)) return text;
            
            try
            {
                // First, split by existing newlines
                string[] paragraphs = text.Split('\n');
                System.Text.StringBuilder result = new System.Text.StringBuilder();
                
                for (int p = 0; p < paragraphs.Length; p++)
                {
                    string paragraph = paragraphs[p].TrimEnd('\r');
                    
                    // If paragraph is short enough, keep as is
                    if (paragraph.Length <= MAX_LINE_LENGTH)
                    {
                        result.Append(paragraph);
                    }
                    else
                    {
                        // Wrap long paragraph
                        int startIndex = 0;
                        while (startIndex < paragraph.Length)
                        {
                            int remainingLength = paragraph.Length - startIndex;
                            
                            if (remainingLength <= MAX_LINE_LENGTH)
                            {
                                // Last chunk, just append it
                                result.Append(paragraph.Substring(startIndex));
                                break;
                            }
                            
                            // Find best break point within MAX_LINE_LENGTH
                            int breakPoint = -1;
                            int searchEnd = Math.Min(startIndex + MAX_LINE_LENGTH, paragraph.Length);
                            
                            // Search backwards from max position for a good break point
                            for (int i = searchEnd - 1; i > startIndex; i--)
                            {
                                char c = paragraph[i];
                                if (Array.IndexOf(ThaiBreakChars, c) >= 0)
                                {
                                    breakPoint = i + 1; // Break after the character
                                    break;
                                }
                            }
                            
                            // If no good break point found, force break at MAX_LINE_LENGTH
                            if (breakPoint <= startIndex)
                            {
                                breakPoint = startIndex + MAX_LINE_LENGTH;
                            }
                            
                            // Append this chunk
                            result.Append(paragraph.Substring(startIndex, breakPoint - startIndex).TrimEnd());
                            result.Append('\n');
                            
                            startIndex = breakPoint;
                            
                            // Skip leading spaces after break
                            while (startIndex < paragraph.Length && paragraph[startIndex] == ' ')
                            {
                                startIndex++;
                            }
                        }
                    }
                    
                    // Add newline between paragraphs (except for last one)
                    if (p < paragraphs.Length - 1)
                    {
                        result.Append('\n');
                    }
                }
                
                return result.ToString();
            }
            catch
            {
                return text;
            }
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
            try { string thai = ThaiTranslationMod.GetMemoryName(key); if (!string.IsNullOrEmpty(thai)) __result = thai; } catch { }
        }
        
        [HarmonyPatch(typeof(DewLocalization), "GetSkillShortDesc")]
        [HarmonyPostfix]
        public static void GetSkillShortDesc_Postfix(string key, ref string __result)
        {
            try { string thai = ThaiTranslationMod.GetMemoryShortDescription(key); if (!string.IsNullOrEmpty(thai)) __result = thai; } catch { }
        }
        
        [HarmonyPatch(typeof(DewLocalization), "GetSkillDescription", new Type[] { typeof(string), typeof(int) })]
        [HarmonyPostfix]
        public static void GetSkillDescription_Postfix(string key, ref List<LocaleNode> __result)
        {
            try 
            { 
                ThaiTranslationMod.LogKey("SkillDesc", key, null);
                string thai = ThaiTranslationMod.GetMemoryDescription(key); 
                if (!string.IsNullOrEmpty(thai)) 
                {
                    Debug.Log("[ThaiTranslation] Replacing description for: " + key);
                    if (__result != null)
                    {
                        __result.Clear();
                        LocaleNode node = new LocaleNode();
                        node.type = LocaleNodeType.Text;
                        node.textData = thai;
                        __result.Add(node);
                    }
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
                string thai = ThaiTranslationMod.GetMemoryLore(key); 
                if (!string.IsNullOrEmpty(thai)) 
                {
                    __result = thai;
                }
            } 
            catch { }
        }
        
        [HarmonyPatch(typeof(DewLocalization), "GetGemName", new Type[] { typeof(string) })]
        [HarmonyPostfix]
        public static void GetGemName_Postfix(string key, ref string __result)
        {
            try { string thai = ThaiTranslationMod.GetEssenceName(key); if (!string.IsNullOrEmpty(thai)) __result = thai; } catch { }
        }
        
        [HarmonyPatch(typeof(DewLocalization), "GetGemDescription", new Type[] { typeof(string) })]
        [HarmonyPostfix]
        public static void GetGemDescription_Postfix(string key, ref string __result)
        {
            try { string thai = ThaiTranslationMod.GetEssenceDescription(key); if (!string.IsNullOrEmpty(thai)) __result = thai; } catch { }
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
    }
}
