using System;
using System.Collections.Generic;
using UnityEngine;

namespace PocketOffice.Economy
{
    [Serializable]
    public class Transaction
    {
        public string Description;
        public long Amount;     // positive = income, negative = expense
        public int Month;
        public int Year;
    }

    public class EconomyManager : MonoBehaviour
    {
        public long CurrentCash { get; private set; }
        public long TotalEarned { get; private set; }
        public long TotalSpent { get; private set; }

        // Loan state
        public long ActiveLoanAmount { get; private set; }
        public float LoanInterestRate { get; private set; } = 0.05f; // 5% monthly

        private readonly List<Transaction> _ledger = new();

        public static event Action<long> OnCashChanged;
        public static event Action OnBankrupt;

        public void Initialize(long startingCash)
        {
            CurrentCash = startingCash;
            TotalEarned = startingCash;
            TotalSpent = 0;
            ActiveLoanAmount = 0;
            _ledger.Clear();
        }

        public void AddRevenue(long amount, string description)
        {
            CurrentCash += amount;
            TotalEarned += amount;
            LogTransaction(description, amount);
            OnCashChanged?.Invoke(CurrentCash);
        }

        public bool Spend(long amount, string description)
        {
            if (CurrentCash < amount)
            {
                Debug.LogWarning($"[Economy] Not enough cash to spend ${amount} for '{description}'");
                return false;
            }
            CurrentCash -= amount;
            TotalSpent += amount;
            LogTransaction(description, -amount);
            OnCashChanged?.Invoke(CurrentCash);
            return true;
        }

        public void ProcessMonthlyCosts(int totalSalary, int monthlyRent)
        {
            long totalCost = totalSalary + monthlyRent;

            // Add loan interest if any
            if (ActiveLoanAmount > 0)
            {
                long interest = (long)(ActiveLoanAmount * LoanInterestRate);
                totalCost += interest;
                ActiveLoanAmount += interest;
                LogTransaction("Loan Interest", -interest);
            }

            CurrentCash -= totalCost;
            TotalSpent += totalCost;
            LogTransaction($"Monthly Costs (Salaries + Rent)", -totalCost);
            OnCashChanged?.Invoke(CurrentCash);

            if (CurrentCash < 0) OnBankrupt?.Invoke();
        }

        public bool TakeLoan(long amount)
        {
            if (ActiveLoanAmount > 0) return false; // One loan at a time
            ActiveLoanAmount = amount;
            AddRevenue(amount, "Business Loan");
            Debug.Log($"[Economy] Loan taken: ${amount} at {LoanInterestRate * 100}% monthly interest");
            return true;
        }

        public bool RepayLoan(long amount)
        {
            if (ActiveLoanAmount <= 0 || CurrentCash < amount) return false;
            long repay = Math.Min(amount, ActiveLoanAmount);
            Spend(repay, "Loan Repayment");
            ActiveLoanAmount -= repay;
            return true;
        }

        private void LogTransaction(string description, long amount)
        {
            var game = Core.GameManager.Instance;
            _ledger.Add(new Transaction
            {
                Description = description,
                Amount = amount,
                Month = game?.Company?.CurrentMonth ?? 0,
                Year = game?.Company?.CurrentYear ?? 0
            });
        }

        public List<Transaction> GetLedger() => new(_ledger);
    }
}
