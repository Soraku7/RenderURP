using Manager;
using UnityEngine;

namespace CameraControl
{
    public class CameraCtrl : MonoBehaviour
    {
        private new Camera camera;
        
        private int _objectindex = 0;
        private GameObject _curModel;

        private bool isAutoRotation = false;
        void Start()
        {
            camera = GetComponent<Camera>();
            _curModel = ScenceManager.Instance.scenceObjects[0];
        }
        void Update()
        {
            ChangeObject();
            Ctrl_Cam_Move();
            Cam_Ctrl_Rotation();
        }
        //镜头的远离和接近
        public void Ctrl_Cam_Move()
        {
            if (Input.GetAxis("Mouse ScrollWheel") > 0)
            {
                transform.Translate(Vector3.forward * 1f);//速度可调  自行调整
            }
            if (Input.GetAxis("Mouse ScrollWheel") < 0)
            {
                transform.Translate(Vector3.forward * -1f);//速度可调  自行调整
            }
        }
        //摄像机的旋转
        public void Cam_Ctrl_Rotation()
        {
            var mouse_x = Input.GetAxis("Mouse X");//获取鼠标X轴移动
            var mouse_y = -Input.GetAxis("Mouse Y");//获取鼠标Y轴移动
            if(Input.GetKeyDown(KeyCode.P)) isAutoRotation = !isAutoRotation;
            if (isAutoRotation)
            {
                transform.RotateAround(_curModel.transform.position, Vector3.up, 45 * Time.deltaTime);
            }
            else
            {
                if (Input.GetKey(KeyCode.Mouse1))
                {
                    transform.RotateAround(_curModel.transform.position, Vector3.up, mouse_x * 5);
                    transform.RotateAround(_curModel.transform.position, transform.right, mouse_y * 5);
                }
            }
        }

        public void ChangeObject()
        {
            if (Input.GetKeyDown(KeyCode.A))
            {
                ScenceManager.Instance.scenceObjects[_objectindex].SetActive(false);
                _objectindex--;
                if (_objectindex < 0)
                {
                    _objectindex = ScenceManager.Instance.scenceObjects.Count - 1;
                }
                
                ScenceManager.Instance.scenceObjects[_objectindex].SetActive(true);
            }

            if (Input.GetKeyDown(KeyCode.D))
            {
                ScenceManager.Instance.scenceObjects[_objectindex].SetActive(false);
                _objectindex++;
                if (_objectindex > ScenceManager.Instance.scenceObjects.Count - 1)
                {
                    _objectindex = 0;
                }
                ScenceManager.Instance.scenceObjects[_objectindex].SetActive(true);
            }
        }
    }
}