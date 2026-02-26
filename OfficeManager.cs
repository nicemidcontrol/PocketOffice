using System;
using System.Collections.Generic;
using UnityEngine;

namespace PocketOffice.Office
{
    public enum RoomType
    {
        Empty,
        Desk,
        MeetingRoom,
        BreakRoom,
        ServerRoom,
        TrainingRoom,
        HROffice,
        ExecutiveSuite
    }

    [Serializable]
    public class RoomTile
    {
        public int X;
        public int Y;
        public int Floor;
        public RoomType Type;

        // Stat buffs this room applies to all employees on this floor
        public int ProductivityBuff;
        public int MoraleBuff;
        public int SkillBuff;

        public RoomTile(int x, int y, int floor, RoomType type)
        {
            X = x; Y = y; Floor = floor; Type = type;
            ApplyRoomBuffs();
        }

        private void ApplyRoomBuffs()
        {
            switch (Type)
            {
                case RoomType.Desk:          ProductivityBuff = 5;  break;
                case RoomType.MeetingRoom:   ProductivityBuff = 8;  MoraleBuff = 3; break;
                case RoomType.BreakRoom:     MoraleBuff = 15; break;
                case RoomType.ServerRoom:    ProductivityBuff = 12; break;
                case RoomType.TrainingRoom:  SkillBuff = 10; break;
                case RoomType.HROffice:      MoraleBuff = 8; break;
                case RoomType.ExecutiveSuite:ProductivityBuff = 5; MoraleBuff = 5; break;
            }
        }
    }

    public class OfficeManager : MonoBehaviour
    {
        public const int FloorWidth = 10;
        public const int FloorHeight = 5;

        private Dictionary<int, RoomTile[,]> _floors = new();
        private int _unlockedFloors = 1;
        private int _baseRentPerFloor = 1000;

        public int UnlockedFloors => _unlockedFloors;

        public void Initialize()
        {
            UnlockFloor(0); // Start with ground floor
        }

        public void UnlockFloor(int floorIndex)
        {
            if (_floors.ContainsKey(floorIndex)) return;
            _floors[floorIndex] = new RoomTile[FloorWidth, FloorHeight];

            // Fill with empty tiles
            for (int x = 0; x < FloorWidth; x++)
                for (int y = 0; y < FloorHeight; y++)
                    _floors[floorIndex][x, y] = new RoomTile(x, y, floorIndex, RoomType.Empty);

            // Default: a few desks
            PlaceRoom(floorIndex, 0, 0, RoomType.Desk);
            PlaceRoom(floorIndex, 1, 0, RoomType.Desk);
            PlaceRoom(floorIndex, 2, 0, RoomType.Desk);

            _unlockedFloors = Mathf.Max(_unlockedFloors, floorIndex + 1);
            Debug.Log($"[OfficeManager] Floor {floorIndex} unlocked.");
        }

        public bool PlaceRoom(int floor, int x, int y, RoomType type)
        {
            if (!_floors.ContainsKey(floor)) return false;
            if (x < 0 || x >= FloorWidth || y < 0 || y >= FloorHeight) return false;

            _floors[floor][x, y] = new RoomTile(x, y, floor, type);
            return true;
        }

        public RoomTile GetTile(int floor, int x, int y)
        {
            if (!_floors.ContainsKey(floor)) return null;
            return _floors[floor][x, y];
        }

        public int GetMonthlyRent() => _unlockedFloors * _baseRentPerFloor;

        /// <summary>Returns the total productivity buff from all rooms across all floors.</summary>
        public int GetTotalProductivityBuff()
        {
            int total = 0;
            foreach (var floor in _floors.Values)
                foreach (var tile in floor)
                    total += tile.ProductivityBuff;
            return total;
        }

        public int GetTotalMoraleBuff()
        {
            int total = 0;
            foreach (var floor in _floors.Values)
                foreach (var tile in floor)
                    total += tile.MoraleBuff;
            return total;
        }
    }
}
