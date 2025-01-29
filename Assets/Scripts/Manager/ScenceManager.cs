using System;
using System.Collections.Generic;
using Base;
using UnityEngine;
using UnityEngine.Serialization;

namespace Manager
{
    public class ScenceManager : SingletonMono<ScenceManager>
    {
        [SerializeField]
        public List<GameObject> scenceObjects = new List<GameObject>();


        private void Update()
        {
            
        }
    }
}