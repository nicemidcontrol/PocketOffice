using System;
using UnityEngine;

namespace PocketOffice.Employees
{
    public enum Personality
    {
        Normal,
        Workaholic,
        Lazy,
        Gossip,
        Perfectionist,
        TeamPlayer,
        LoneStar
    }

    public enum EmployeeRole
    {
        Developer,
        Designer,
        Marketer,
        HRSpecialist,
        Accountant,
        Manager,
        Intern
    }

    [Serializable]
    public class Employee
    {
        // Identity
        public string Id;
        public string FirstName;
        public string LastName;
        public string FullName => $"{FirstName} {LastName}";
        public Personality Personality;
        public EmployeeRole Role;
        public Sprite Portrait; // Pixel art portrait

        // Core Stats (1–100)
        public int Skill;
        public int Motivation;
        public int Teamwork;
        public int Creativity;

        // Career
        public int Level;
        public int ExperiencePoints;
        public int ExperienceToNextLevel => Level * 100;

        // Financials
        public int MonthlySalary;
        public bool IsHired;

        // State
        public bool IsAssignedToProject;
        public string CurrentProjectId;
        public bool IsBurnedOut;

        // Computed
        public float EffectiveProductivity =>
            IsAssignedToProject && !IsBurnedOut
                ? (Skill + Motivation * PersonalityMultiplier()) / 2f
                : 0f;

        public Employee(string firstName, string lastName, EmployeeRole role, Personality personality)
        {
            Id = Guid.NewGuid().ToString();
            FirstName = firstName;
            LastName = lastName;
            Role = role;
            Personality = personality;
            Level = 1;
            ExperiencePoints = 0;
            IsHired = false;
            IsBurnedOut = false;

            // Randomize base stats
            var rng = new System.Random();
            Skill = rng.Next(20, 70);
            Motivation = rng.Next(20, 70);
            Teamwork = rng.Next(20, 70);
            Creativity = rng.Next(20, 70);

            // Personality adjustments
            ApplyPersonalityBonuses();

            MonthlySalary = CalculateBaseSalary();
        }

        private void ApplyPersonalityBonuses()
        {
            switch (Personality)
            {
                case Personality.Workaholic:
                    Skill = Mathf.Min(100, Skill + 15);
                    Motivation = Mathf.Min(100, Motivation + 20);
                    break;
                case Personality.Lazy:
                    Motivation -= 20;
                    Motivation = Mathf.Max(5, Motivation);
                    break;
                case Personality.TeamPlayer:
                    Teamwork = Mathf.Min(100, Teamwork + 25);
                    break;
                case Personality.Perfectionist:
                    Skill = Mathf.Min(100, Skill + 20);
                    Creativity = Mathf.Max(5, Creativity - 10); // slow but precise
                    break;
                case Personality.Gossip:
                    Teamwork = Mathf.Min(100, Teamwork + 10);
                    Motivation = Mathf.Max(5, Motivation - 10);
                    break;
            }
        }

        private float PersonalityMultiplier()
        {
            return Personality switch
            {
                Personality.Workaholic => 1.3f,
                Personality.Lazy => 0.6f,
                Personality.Perfectionist => 1.1f,
                Personality.Gossip => 0.85f,
                _ => 1.0f
            };
        }

        private int CalculateBaseSalary()
        {
            int baseSalary = Role switch
            {
                EmployeeRole.Intern => 500,
                EmployeeRole.Developer => 2000,
                EmployeeRole.Designer => 1800,
                EmployeeRole.Marketer => 1700,
                EmployeeRole.HRSpecialist => 1600,
                EmployeeRole.Accountant => 1900,
                EmployeeRole.Manager => 2500,
                _ => 1500
            };
            return baseSalary + (Skill * 10) + (Level * 100);
        }

        public void GainExperience(int amount)
        {
            ExperiencePoints += amount;
            while (ExperiencePoints >= ExperienceToNextLevel)
            {
                ExperiencePoints -= ExperienceToNextLevel;
                LevelUp();
            }
        }

        private void LevelUp()
        {
            Level++;
            Skill = Mathf.Min(100, Skill + 5);
            Motivation = Mathf.Min(100, Motivation + 3);
            MonthlySalary = CalculateBaseSalary();
            Debug.Log($"[Employee] {FullName} leveled up to Level {Level}!");
        }

        public void AdjustMotivation(int delta)
        {
            Motivation = Mathf.Clamp(Motivation + delta, 0, 100);
            IsBurnedOut = Motivation <= 10;
        }

        public override string ToString() =>
            $"{FullName} | {Role} | Lv.{Level} | Skill:{Skill} Motivation:{Motivation} | ${MonthlySalary}/mo";
    }
}
