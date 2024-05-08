using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// 敵生成の制御クラス
/// </summary>
public class SpawnController : MonoBehaviour
{
    [SerializeField] Enemy[] enemyPrefabs;
    [SerializeField] Transform spawnPoint;

    float elapsedTime = 0f;
    float nextSpawnTime = 2f;

    bool isSpawn = false;

    /// <summary>
    /// 敵の生成を開始する
    /// </summary>
    public void StartSpawn()
    {
        this.isSpawn = true;
        SpawnEnemy();
    }

    /// <summary>
    /// 敵の生成を止める
    /// </summary>
    public void StopSpawn()
    {
        this.isSpawn = false;
    }

    // Update is called once per frame
    void Update()
    {
        if (this.isSpawn)
        {
            SpawnEnemyUpdate();
        }
    }

    void SpawnEnemyUpdate()
    {
        //経過時間を加算する
        this.elapsedTime += Time.deltaTime;
        if (this.elapsedTime < this.nextSpawnTime)
        {
            return;
        }

        SpawnEnemy();
    }

    void SpawnEnemy()
    {
        var enemy = Instantiate(this.enemyPrefabs[Random.Range(0, this.enemyPrefabs.Length)]);
        //SpawnPointの-2.0〜2.0 X座標をランダムに生成させる
        enemy.transform.position = this.spawnPoint.position + Random.Range(-2f, 2f) * Vector3.right;

        //SpawnControllerのインスタンスを渡す
        enemy.Initialize(this);

        this.elapsedTime = 0f;
    }

    /// <summary>
    /// 敵を倒したことを通知する
    /// </summary>
    public void DeathDetected()
    {
        SpawnEnemy();

        //5%ずつ生成速度が上がる
        //ただし0.2sec未満にはならない
        this.nextSpawnTime = Mathf.Max(0.2f, this.nextSpawnTime * 0.95f);
    }
}
