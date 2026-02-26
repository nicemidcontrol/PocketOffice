using System;
using System.Collections.Generic;
using UnityEngine;

namespace PocketOffice.Events
{
    public enum EventOutcomeType { MoneyGain, MoneyLoss, ReputationGain, ReputationLoss, MotivationGain, MotivationLoss }

    [Serializable]
    public class EventChoice
    {
        public string Label;
        public string ResultText;
        public EventOutcomeType OutcomeType;
        public int OutcomeValue;
    }

    [Serializable]
    public class CorporateEvent
    {
        public string Title;
        public string Description;
        public string IconKey; // maps to sprite atlas key
        public List<EventChoice> Choices;
        public float TriggerChance; // 0.0–1.0 per month
    }

    public class EventManager : MonoBehaviour
    {
        private List<CorporateEvent> _eventPool = new();
        private System.Random _rng = new();

        public static event Action<CorporateEvent> OnEventTriggered;

        public void Initialize()
        {
            BuildEventPool();
        }

        private void BuildEventPool()
        {
            _eventPool = new List<CorporateEvent>
            {
                new CorporateEvent
                {
                    Title = "🎉 Investor Visit",
                    Description = "A potential investor wants to tour your office. Impressions matter!",
                    IconKey = "icon_investor",
                    TriggerChance = 0.15f,
                    Choices = new List<EventChoice>
                    {
                        new EventChoice { Label = "Clean Up & Impress", ResultText = "Investor loved it!", OutcomeType = EventOutcomeType.ReputationGain, OutcomeValue = 20 },
                        new EventChoice { Label = "Business as Usual", ResultText = "Investor was unimpressed.", OutcomeType = EventOutcomeType.ReputationLoss, OutcomeValue = 5 }
                    }
                },
                new CorporateEvent
                {
                    Title = "🔥 Employee Burnout",
                    Description = "Half your team is showing signs of burnout. What do you do?",
                    IconKey = "icon_burnout",
                    TriggerChance = 0.20f,
                    Choices = new List<EventChoice>
                    {
                        new EventChoice { Label = "Paid Team Retreat", ResultText = "Team morale soared!", OutcomeType = EventOutcomeType.MoneyLoss, OutcomeValue = 3000 },
                        new EventChoice { Label = "Ignore It", ResultText = "Two employees quit.", OutcomeType = EventOutcomeType.MotivationLoss, OutcomeValue = 30 }
                    }
                },
                new CorporateEvent
                {
                    Title = "📱 Viral Social Media Post",
                    Description = "A staff member posted something about the company — it's going viral!",
                    IconKey = "icon_viral",
                    TriggerChance = 0.10f,
                    Choices = new List<EventChoice>
                    {
                        new EventChoice { Label = "Embrace the Moment", ResultText = "Brand awareness exploded!", OutcomeType = EventOutcomeType.ReputationGain, OutcomeValue = 30 },
                        new EventChoice { Label = "Issue Damage Control", ResultText = "Contained, but costly.", OutcomeType = EventOutcomeType.MoneyLoss, OutcomeValue = 1000 }
                    }
                },
                new CorporateEvent
                {
                    Title = "🎂 Office Birthday Party",
                    Description = "It's someone's birthday! Celebrate or focus on deadlines?",
                    IconKey = "icon_party",
                    TriggerChance = 0.25f,
                    Choices = new List<EventChoice>
                    {
                        new EventChoice { Label = "Throw a Party!", ResultText = "Everyone's happy!", OutcomeType = EventOutcomeType.MotivationGain, OutcomeValue = 15 },
                        new EventChoice { Label = "Politely Decline", ResultText = "Morale dipped a little.", OutcomeType = EventOutcomeType.MotivationLoss, OutcomeValue = 5 }
                    }
                },
                new CorporateEvent
                {
                    Title = "📰 Press Coverage",
                    Description = "A journalist wants to feature your company in a tech magazine.",
                    IconKey = "icon_press",
                    TriggerChance = 0.12f,
                    Choices = new List<EventChoice>
                    {
                        new EventChoice { Label = "Accept Interview", ResultText = "Great exposure!", OutcomeType = EventOutcomeType.ReputationGain, OutcomeValue = 25 },
                        new EventChoice { Label = "Decline for Now", ResultText = "Missed opportunity.", OutcomeType = EventOutcomeType.ReputationLoss, OutcomeValue = 3 }
                    }
                },
                new CorporateEvent
                {
                    Title = "💰 Government Grant",
                    Description = "Your company qualifies for a small business development grant!",
                    IconKey = "icon_money",
                    TriggerChance = 0.08f,
                    Choices = new List<EventChoice>
                    {
                        new EventChoice { Label = "Apply!", ResultText = "Grant approved! $5,000 received.", OutcomeType = EventOutcomeType.MoneyGain, OutcomeValue = 5000 }
                    }
                }
            };
        }

        public void TryTriggerRandomEvent()
        {
            foreach (var ev in _eventPool)
            {
                if (_rng.NextDouble() < ev.TriggerChance / 30f) // distribute across ~30 days
                {
                    OnEventTriggered?.Invoke(ev);
                    return; // Only one event per day
                }
            }
        }

        public void ResolveEvent(CorporateEvent ev, EventChoice choice)
        {
            var game = Core.GameManager.Instance;

            switch (choice.OutcomeType)
            {
                case EventOutcomeType.MoneyGain:
                    game.EconomyManager.AddRevenue(choice.OutcomeValue, ev.Title); break;
                case EventOutcomeType.MoneyLoss:
                    game.EconomyManager.Spend(choice.OutcomeValue, ev.Title); break;
                case EventOutcomeType.ReputationGain:
                    game.Company.Reputation = Mathf.Min(1000, game.Company.Reputation + choice.OutcomeValue); break;
                case EventOutcomeType.ReputationLoss:
                    game.Company.Reputation = Mathf.Max(0, game.Company.Reputation - choice.OutcomeValue); break;
                case EventOutcomeType.MotivationGain:
                case EventOutcomeType.MotivationLoss:
                    int delta = choice.OutcomeType == EventOutcomeType.MotivationGain ? choice.OutcomeValue : -choice.OutcomeValue;
                    foreach (var emp in game.EmployeeManager.GetAllEmployees())
                        if (emp.IsHired) emp.AdjustMotivation(delta / 3);
                    break;
            }

            Core.GameManager.BroadcastMessage($"[{ev.Title}] {choice.ResultText}");
        }
    }
}
