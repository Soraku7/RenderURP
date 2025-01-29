using UnityEngine;

namespace Base
{
    /// <summary>
    /// 继承MonoBehaviour的泛型单例基类
    /// </summary>
    public class SingletonMono<T> : MonoBehaviour where T : MonoBehaviour
    {
        private static T instance;

        public static T Instance
        {
            get
            {
                if (instance == null)
                {
                    instance = FindObjectOfType<T>();
                    if (instance == null)
                    {
                        GameObject go = new GameObject(typeof(T).Name); // 创建游戏对象
                        instance = go.AddComponent<T>(); // 挂载脚本
                    }
                }
                return instance;
            }
        }

    
        // 构造方法私有化，防止外部 new 对象
        protected SingletonMono() { }
    }
}