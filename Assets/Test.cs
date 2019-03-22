using UnityEngine;

public class Test : MonoBehaviour
{
    public Renderer[] rs;

    public Material m;
    

    private int count = 0;


    public void Explode()
    {
        Material temp = new Material(m);

        temp.SetFloat("_StartTime", Time.timeSinceLevelLoad);
        temp.color = Color.red;

        count++;

        switch(count)
        {
            case 1:
                rs[0].material = temp;
                break;
            case 2:
                rs[1].material = temp;
                break;
            case 3:
                rs[2].material = temp;
                break;

        }
    }
}