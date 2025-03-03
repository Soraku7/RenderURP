using System;
using UnityEngine;

namespace Clock
{
    public class Clock : MonoBehaviour
    {
        public Material clockMat;
        
        private int hourAnglePropID;
        private int minuteAnglePropID;
        private int secondAnglePropID;
        private void Start()
        {
            if (clockMat == null) return;
            
            hourAnglePropID = Shader.PropertyToID("_HourHandAngle");
            minuteAnglePropID = Shader.PropertyToID("_MinuteHandAngle");
            secondAnglePropID = Shader.PropertyToID("_SecondHandAngle");
            
            
        }

        private void Update()
        {
            //秒针
            int second = DateTime.Now.Second;
            float secondAngle = second / 60.0f * 360.0f;
            clockMat.SetFloat(secondAnglePropID, secondAngle);
            
            //分针
            int minute = DateTime.Now.Minute;
            float minuteAngle = minute / 60.0f * 360.0f;
            clockMat.SetFloat(minuteAnglePropID, minuteAngle);
            
            //时针
            int hour = DateTime.Now.Hour;
            float hourAngle = (hour % 12) / 12.0f * 360.0f + minuteAngle / 360.0f * 30.0f;
            clockMat.SetFloat(hourAnglePropID, hourAngle);
        }
    }
}