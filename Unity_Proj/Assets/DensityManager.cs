using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;
using UnityEngine.Networking;
using TMPro;

public class DensityManager : MonoBehaviour
{

    public int regions_per_dim = 10;
    public int box_width = 100;
    public GameObject regionPrefab;
    public float waitBetweenFrames = 1.0f;
    private List<GameObject> regionsGOList;
    private int max_region_density = 0;
    public Material orig_reg_mat;
    private Material reg_mat_instance;

    public TextMeshProUGUI errorText;

    private string filePath = Path.Combine(Application.streamingAssetsPath, "densities_result.txt");

    IEnumerator FindFile() {

        #if UNITY_ANDROID && !UNITY_EDITOR
            filePath = Path.Combine(Application.persistentDataPath, "densities_result.txt");
            if (!File.Exists(filePath))
            {
                // If the file doesn't exist in the persistent data path, copy it from the streaming assets
                string streamingAssetsPath = Path.Combine(Application.streamingAssetsPath, "densities_result.txt");
                UnityWebRequest www = UnityWebRequest.Get(streamingAssetsPath);
                yield return www.SendWebRequest();

                if (www.isNetworkError || www.isHttpError)
                {
                    errorText.text = "Error loading results file: " + www.error;
                    yield break;
                }

                File.WriteAllText(filePath, www.downloadHandler.text);
            }
        #endif

        if (!File.Exists(filePath))
        {
            errorText.text = "Can't find results file.";
        }
        else
        {
            StartCoroutine(FindMaxRegion(filePath));
        }
        yield break;
    }

    // Start is called before the first frame update
    void Start()
    {   
        // Holds the regions in the order they get created
        regionsGOList= new List<GameObject>();

        // Unity spawns objects at their center, so an offset
        // is necessary
        float centerOffset = ((float)box_width / regions_per_dim) / 2.0f;

        // The regionPrefab has scale 1, so there needs to be a 
        // scaling factor to make sure all regions fit together
        float regionScaleFactor = (float)box_width / regions_per_dim;
        Vector3 regionScale = new Vector3(regionScaleFactor, regionScaleFactor, regionScaleFactor);

        // Loop through all of the regions, spawing 
        // a regionPrefab at the center of that location
        // with the correct scale
        for (float x=0.0f; x<box_width; x+=regionScaleFactor) {
            for (float y=0.0f; y<box_width; y+=regionScaleFactor) {
                for (float z=0.0f; z<box_width; z+=regionScaleFactor) {
                    Vector3 spawnPos = new Vector3(x+centerOffset, y+centerOffset, z+centerOffset);
                    GameObject new_region = Instantiate(regionPrefab, spawnPos, Quaternion.identity);
                    new_region.transform.localScale = regionScale;

                    // Create a new material instance
                    reg_mat_instance = new Material(orig_reg_mat);

                    // Apply the new material instance to the renderer
                    new_region.GetComponent<Renderer>().material = reg_mat_instance;

                    // Add region to list
                    regionsGOList.Add(new_region);
                }
            }
        }


        StartCoroutine(FindFile());

    }

    IEnumerator FindMaxRegion(string filePath) {
        // Loop through the whole list of densities and 
        using (StreamReader reader = new StreamReader(filePath)) {
            while (!reader.EndOfStream) {
                string line = reader.ReadLine();
                if (line != null) {
                    // Split line into densities
                    string[] densities = line.Split(',');
                    
                    // Loop through the densities and compare to max
                    for (int i=0; i<densities.Length; i++) {
                        int d = int.Parse(densities[i]);
                        if (d > max_region_density) {
                            max_region_density = d;
                        }
                    }
                }
            }
        }
        StartCoroutine(VisualizeDensities(filePath));
        yield break;
    }

    IEnumerator VisualizeDensities(string filePath)
    {
        // Read the file asynchronously to avoid freezing the game
        using (StreamReader reader = new StreamReader(filePath))
        {
            while (!reader.EndOfStream)
            {
                string line = reader.ReadLine();
                if (line != null)
                {
                    // Split the line into individual densities
                    string[] densities = line.Split(',');

                    // Change region alpha based on the density
                    for (int i = 0; i < densities.Length; i++)
                    {
                        int d = int.Parse(densities[i]);
                        GameObject cur_region = regionsGOList[i];
                        Material cur_mat = cur_region.GetComponent<Renderer>().material;
                        Debug.Log(d);
                        float colorLerped = Mathf.Lerp(0.0f, 1.0f, (float)d/max_region_density);
                        Debug.Log(colorLerped);
                        // int roundedColorNew = Mathf.FloorToInt(colorLerped);
                        // if (colorLerped < 0) {
                            // newColor = new Color(0, 0, -roundedColorNew);
                        // }
                        // else {
                        Color newColor = new Color(colorLerped, 0, 0);
                        newColor.a = colorLerped;
                        // }
                        cur_mat.color = newColor;
                    }

                }

                // Yield for one frame before processing the next line
                yield return new WaitForSeconds(waitBetweenFrames);
            }
        }

        Debug.Log("Particle spawning complete!");
    }
}
