using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using PocketOffice.Employees;

namespace PocketOffice.Projects
{
    public enum ProjectStatus { Available, Active, Completed, Failed }

    [Serializable]
    public class ClientProject
    {
        public string Id;
        public string ClientName;
        public string ProjectTitle;
        public string Description;
        public int RequiredSkillPoints;    // Total skill needed
        public int DeadlineDays;
        public int DaysElapsed;
        public int RewardMoney;
        public int RewardReputation;
        public int PenaltyReputation;
        public ProjectStatus Status;
        public List<string> AssignedEmployeeIds = new();

        public float Progress => RequiredSkillPoints > 0
            ? Mathf.Clamp01((float)DaysElapsed * DailyOutput / RequiredSkillPoints)
            : 0f;

        public float DailyOutput; // Set when employees are assigned
        public bool IsOverdue => DaysElapsed >= DeadlineDays && Status == ProjectStatus.Active;
    }

    public class ProjectManager : MonoBehaviour
    {
        private List<ClientProject> _projects = new();
        private readonly string[] _clientNames = { "Acme Corp", "TechNova", "MegaDeal Ltd", "PixelBrand", "CloudFirst Inc" };
        private readonly string[] _projectTitles = { "Website Revamp", "App Development", "Brand Campaign", "Data Migration", "Office System" };

        public static event Action<ClientProject> OnProjectCompleted;
        public static event Action<ClientProject> OnProjectFailed;

        public void Initialize() => _projects.Clear();

        public void GenerateNewProjects(int count)
        {
            var rng = new System.Random();
            for (int i = 0; i < count; i++)
            {
                var project = new ClientProject
                {
                    Id = Guid.NewGuid().ToString(),
                    ClientName = _clientNames[rng.Next(_clientNames.Length)],
                    ProjectTitle = _projectTitles[rng.Next(_projectTitles.Length)],
                    RequiredSkillPoints = rng.Next(100, 500),
                    DeadlineDays = rng.Next(10, 30),
                    RewardMoney = rng.Next(2000, 20000),
                    RewardReputation = rng.Next(5, 25),
                    PenaltyReputation = rng.Next(5, 15),
                    Status = ProjectStatus.Available
                };
                _projects.Add(project);
                Debug.Log($"[ProjectManager] New project available: {project.ProjectTitle} from {project.ClientName}");
            }
        }

        public bool AssignEmployeesToProject(string projectId, List<Employee> employees)
        {
            var project = _projects.FirstOrDefault(p => p.Id == projectId);
            if (project == null || project.Status != ProjectStatus.Available) return false;

            project.Status = ProjectStatus.Active;
            project.AssignedEmployeeIds = employees.Select(e => e.Id).ToList();
            project.DailyOutput = employees.Sum(e => e.EffectiveProductivity);

            foreach (var emp in employees) emp.IsAssignedToProject = true;
            return true;
        }

        public void TickProjects()
        {
            foreach (var project in _projects.Where(p => p.Status == ProjectStatus.Active).ToList())
            {
                project.DaysElapsed++;

                if (project.Progress >= 1f)
                    CompleteProject(project);
                else if (project.IsOverdue)
                    FailProject(project);
            }
        }

        private void CompleteProject(ClientProject project)
        {
            project.Status = ProjectStatus.Completed;
            GameManager.Instance.EconomyManager.AddRevenue(project.RewardMoney, "Project: " + project.ProjectTitle);
            GameManager.Instance.Company.Reputation += project.RewardReputation;
            FreeEmployees(project);
            OnProjectCompleted?.Invoke(project);
            Core.GameManager.BroadcastMessage($"✅ Project '{project.ProjectTitle}' completed! +${project.RewardMoney}");
        }

        private void FailProject(ClientProject project)
        {
            project.Status = ProjectStatus.Failed;
            GameManager.Instance.Company.Reputation =
                Mathf.Max(0, GameManager.Instance.Company.Reputation - project.PenaltyReputation);
            FreeEmployees(project);
            OnProjectFailed?.Invoke(project);
            Core.GameManager.BroadcastMessage($"❌ Project '{project.ProjectTitle}' failed. -{project.PenaltyReputation} reputation");
        }

        private void FreeEmployees(ClientProject project)
        {
            var allEmployees = GameManager.Instance.EmployeeManager.GetAllEmployees();
            foreach (var emp in allEmployees.Where(e => project.AssignedEmployeeIds.Contains(e.Id)))
            {
                emp.IsAssignedToProject = false;
                emp.GainExperience(50);
                emp.AdjustMotivation(project.Status == ProjectStatus.Completed ? +10 : -15);
            }
        }

        public List<ClientProject> GetActiveProjects() => _projects.Where(p => p.Status == ProjectStatus.Active).ToList();
        public List<ClientProject> GetAvailableProjects() => _projects.Where(p => p.Status == ProjectStatus.Available).ToList();
        public void LoadProjects(List<ClientProject> projects) { _projects = projects ?? new List<ClientProject>(); }
    }
}
