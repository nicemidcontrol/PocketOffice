using System;
using System.Collections.Generic;
using UnityEngine;
using PocketOffice.Employees;
using PocketOffice.Economy;
using PocketOffice.Projects;
using PocketOffice.Events;

namespace PocketOffice.Core
{
    public enum CompanyTier
    {
        Startup,    // 1-5 employees, 1 floor
        SME,        // 6-20 employees, 2-3 floors
        Enterprise, // 21-50 employees, 4-6 floors
        GlobalCorp  // 51+ employees, 7+ floors
    }

    [Serializable]
    public class CompanyData
    {
        public string CompanyName;
        public int Reputation;     // 0–1000
        public CompanyTier Tier;
        public int CurrentYear;
        public int CurrentMonth;
        public int CurrentDay;
        public List<string> UnlockedDepartments = new();
    }

    public class GameManager : MonoBehaviour
    {
        // --- Singleton ---
        public static GameManager Instance { get; private set; }

        // --- Sub-Managers ---
        public EmployeeManager EmployeeManager { get; private set; }
        public EconomyManager EconomyManager { get; private set; }
        public ProjectManager ProjectManager { get; private set; }
        public EventManager EventManager { get; private set; }
        public OfficeManager OfficeManager { get; private set; }

        // --- Company State ---
        public CompanyData Company { get; private set; }

        // --- Time ---
        [SerializeField] private float dayDurationSeconds = 10f;
        private float _dayTimer;
        public bool IsPaused { get; private set; }

        // --- Events ---
        public static event Action<int> OnDayPassed;
        public static event Action<int> OnMonthPassed;
        public static event Action<int> OnYearPassed;
        public static event Action<CompanyTier> OnTierUpgraded;
        public static event Action<string> OnGameMessage;

        // =============================================
        // UNITY LIFECYCLE
        // =============================================

        private void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }
            Instance = this;
            DontDestroyOnLoad(gameObject);

            InitializeManagers();
        }

        private void Start()
        {
            NewGame("My Startup Inc.");
        }

        private void Update()
        {
            if (IsPaused) return;

            _dayTimer += Time.deltaTime;
            if (_dayTimer >= dayDurationSeconds)
            {
                _dayTimer = 0f;
                AdvanceDay();
            }
        }

        // =============================================
        // INITIALIZATION
        // =============================================

        private void InitializeManagers()
        {
            EmployeeManager = gameObject.AddComponent<EmployeeManager>();
            EconomyManager = gameObject.AddComponent<EconomyManager>();
            ProjectManager = gameObject.AddComponent<ProjectManager>();
            EventManager = gameObject.AddComponent<EventManager>();
            OfficeManager = gameObject.AddComponent<OfficeManager>();
        }

        public void NewGame(string companyName)
        {
            Company = new CompanyData
            {
                CompanyName = companyName,
                Reputation = 10,
                Tier = CompanyTier.Startup,
                CurrentYear = 2024,
                CurrentMonth = 1,
                CurrentDay = 1,
                UnlockedDepartments = new List<string> { "General" }
            };

            EconomyManager.Initialize(startingCash: 10000);
            ProjectManager.Initialize();
            EventManager.Initialize();

            BroadcastMessage($"Welcome to {companyName}! Let's build something great.");
            Debug.Log("[GameManager] New game started.");
        }

        // =============================================
        // TIME
        // =============================================

        private void AdvanceDay()
        {
            Company.CurrentDay++;
            OnDayPassed?.Invoke(Company.CurrentDay);

            ProjectManager.TickProjects();
            EventManager.TryTriggerRandomEvent();

            if (Company.CurrentDay > 30)
            {
                Company.CurrentDay = 1;
                AdvanceMonth();
            }
        }

        private void AdvanceMonth()
        {
            Company.CurrentMonth++;
            OnMonthPassed?.Invoke(Company.CurrentMonth);

            // Monthly costs
            EconomyManager.ProcessMonthlyCosts(
                EmployeeManager.GetTotalMonthlySalary(),
                OfficeManager.GetMonthlyRent()
            );

            // New project opportunities arrive
            ProjectManager.GenerateNewProjects(count: 2);

            if (Company.CurrentMonth > 12)
            {
                Company.CurrentMonth = 1;
                AdvanceYear();
            }

            CheckTierUpgrade();
        }

        private void AdvanceYear()
        {
            Company.CurrentYear++;
            OnYearPassed?.Invoke(Company.CurrentYear);

            // Annual review
            int annualScore = CalculateAnnualScore();
            BroadcastMessage($"Annual Review: Score {annualScore}/100 — Year {Company.CurrentYear}");

            // Reputation bump
            Company.Reputation = Mathf.Min(1000, Company.Reputation + annualScore / 10);
        }

        // =============================================
        // TIER UPGRADE
        // =============================================

        private void CheckTierUpgrade()
        {
            var newTier = Company.Tier;
            int employeeCount = EmployeeManager.HiredCount;
            long cash = EconomyManager.TotalEarned;

            if (employeeCount >= 51 && cash >= 1_000_000 && Company.Reputation >= 500)
                newTier = CompanyTier.GlobalCorp;
            else if (employeeCount >= 21 && cash >= 200_000 && Company.Reputation >= 200)
                newTier = CompanyTier.Enterprise;
            else if (employeeCount >= 6 && cash >= 30_000 && Company.Reputation >= 50)
                newTier = CompanyTier.SME;

            if (newTier != Company.Tier)
            {
                Company.Tier = newTier;
                OnTierUpgraded?.Invoke(newTier);
                BroadcastMessage($"🎉 Congratulations! You've reached {newTier}!");
            }
        }

        // =============================================
        // SCORING
        // =============================================

        private int CalculateAnnualScore()
        {
            float reputationScore = Mathf.Min(Company.Reputation / 10f, 30f);
            float financeScore = Mathf.Min(EconomyManager.CurrentCash / 10000f, 40f);
            float employeeScore = Mathf.Min(EmployeeManager.AverageMotivation / 100f * 30f, 30f);
            return Mathf.RoundToInt(reputationScore + financeScore + employeeScore);
        }

        // =============================================
        // CONTROLS
        // =============================================

        public void TogglePause() => IsPaused = !IsPaused;
        public void SetSpeed(float multiplier) => dayDurationSeconds = 10f / Mathf.Clamp(multiplier, 0.5f, 4f);

        // =============================================
        // SAVE / LOAD
        // =============================================

        public void SaveGame() => SaveSystem.Save(BuildSaveData());
        public void LoadGame() => ApplySaveData(SaveSystem.Load());

        private SaveData BuildSaveData()
        {
            return new SaveData
            {
                CompanyData = Company,
                Employees = EmployeeManager.GetAllEmployees(),
                Cash = EconomyManager.CurrentCash,
                ActiveProjects = ProjectManager.GetActiveProjects()
            };
        }

        private void ApplySaveData(SaveData data)
        {
            if (data == null) return;
            Company = data.CompanyData;
            EconomyManager.Initialize(data.Cash);
            EmployeeManager.LoadEmployees(data.Employees);
            ProjectManager.LoadProjects(data.ActiveProjects);
        }

        // =============================================
        // UTILITY
        // =============================================

        public static void BroadcastMessage(string message)
        {
            OnGameMessage?.Invoke(message);
            Debug.Log($"[Game] {message}");
        }

        public string GetCurrentDateString() =>
            $"Month {Company.CurrentMonth}, Year {Company.CurrentYear}";
    }
}
