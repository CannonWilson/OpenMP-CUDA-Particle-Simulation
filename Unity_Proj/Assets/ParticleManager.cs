using System;
using System.Collections;
using System.IO;
using UnityEngine;
using TMPro;
using UnityEngine.Networking;


public class ParticleManager : MonoBehaviour
{
    public GameObject spherePrefab; // The sphere prefab to be instantiated
    public float waitBetweenFrames = 1f;
    public float scaleFactor = 100.0f;
    public TextMeshProUGUI errorText;

    private string filePath = Path.Combine(Application.streamingAssetsPath, "results.txt");

    IEnumerator FindFile() {

        #if UNITY_ANDROID && !UNITY_EDITOR
            filePath = Path.Combine(Application.persistentDataPath, "results.txt");
            if (!File.Exists(filePath))
            {
                // If the file doesn't exist in the persistent data path, copy it from the streaming assets
                string streamingAssetsPath = Path.Combine(Application.streamingAssetsPath, "results.txt");
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
            StartCoroutine(SpawnParticlesFromFile(filePath));
        }
        yield break;
    }



    void Start()
    {
        // Replace with the path to your text file
        // string filePath = Path.Combine(Application.streamingAssetsPath, "results.txt");
        // #if UNITY_ANDROID && !UNITY_EDITOR
        //     filePath = "jar:file://" + Application.dataPath + "!/assets/" + "results.txt";
        // #endif
        // if(!File.Exists(filePath)) {
        //     errorText.text = "Can't find results file.";
        // }
        // else {
        //     StartCoroutine(SpawnParticlesFromFile(filePath));
        // }
        StartCoroutine(FindFile());

        // string filePath = "Assets/results.txt";
        // if (!File.Exists(filePath)) {
        //     filePath = Path.Combine(Application.streamingAssetsPath, "results.txt");
        //     if(!File.Exists(filePath)) {
        //         errorText.text = "Can't find results file.";
        //     }
        //     else {
        //         StartCoroutine(SpawnParticlesFromFile(filePath));    
        //     }
        // }
        // else {
        //     StartCoroutine(SpawnParticlesFromFile(filePath));
        // }
    }

    IEnumerator SpawnParticlesFromFile(string filePath)
    {
        // Read the file asynchronously to avoid freezing the game
        using (StreamReader reader = new StreamReader(filePath))
        {
            while (!reader.EndOfStream)
            {
                string line = reader.ReadLine();
                if (line != null)
                {
                    // Split the line into individual positions
                    string[] positions = line.Split(',');

                    // Check if there are at least three components for each particle
                    if (positions.Length % 3 == 0)
                    {

                        // Delete all existing particles
                        GameObject[] particles = GameObject.FindGameObjectsWithTag("Particle");
                        foreach (GameObject particle in particles)
                        {
                            Destroy(particle);
                        }

                        // Spawn particles based on the positions
                        for (int i = 0; i < positions.Length; i += 3)
                        {
                            // Parse positions as floats
                            float x = float.Parse(positions[i]) / scaleFactor;
                            float y = float.Parse(positions[i + 1]) / scaleFactor;
                            float z = float.Parse(positions[i + 2]) / scaleFactor;

                            // Instantiate the sphere at the specified position
                            GameObject sphere = Instantiate(spherePrefab, new Vector3(x, y, z), Quaternion.identity);
                            sphere.transform.localScale = spherePrefab.transform.localScale / scaleFactor;
                        }
                    }
                    else
                    {
                        Debug.LogError("Invalid line format: " + line);
                    }
                }

                // Yield for one frame before processing the next line
                yield return new WaitForSeconds(waitBetweenFrames);
            }
        }

        Debug.Log("Particle spawning complete!");
    }
}
