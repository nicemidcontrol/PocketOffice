using System;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using PocketOffice.Employees;
using PocketOffice.Projects;

namespace PocketOffice.Core
{
    [Serializable]
    public class SaveData
    {
        public CompanyData CompanyData;
        public List<Employee> Employees;
        public long Cash;
        public List<ClientProject> ActiveProjects;
        public string SaveTimestamp;
    }

    public static class SaveSystem
    {
        private static readonly string SavePath = Path.Combine(Application.persistentDataPath, "pocketoffice_save.json");

        public static void Save(SaveData data)
        {
            data.SaveTimestamp = DateTime.UtcNow.ToString("o");
            string json = JsonUtility.ToJson(data, prettyPrint: true);
            File.WriteAllText(SavePath, json);
            Debug.Log($"[SaveSystem] Game saved to {SavePath}");
        }

        public static SaveData Load()
        {
            if (!File.Exists(SavePath))
            {
                Debug.Log("[SaveSystem] No save file found.");
                return null;
            }
            string json = File.ReadAllText(SavePath);
            var data = JsonUtility.FromJson<SaveData>(json);
            Debug.Log($"[SaveSystem] Game loaded. Saved at: {data.SaveTimestamp}");
            return data;
        }

        public static void DeleteSave()
        {
            if (File.Exists(SavePath)) File.Delete(SavePath);
            Debug.Log("[SaveSystem] Save file deleted.");
        }

        public static bool SaveExists() => File.Exists(SavePath);
    }
}
