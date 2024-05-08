using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// 敵の制御
/// </summary>
public class Enemy : MonoBehaviour
{
    /// <summary>
    /// すでに倒されているかどうか
    /// </summary>
    public bool IsDead { get; private set; }

    SpawnController spawnController;

    /// <summary>
    /// 初期化
    /// </summary>
    public void Initialize(SpawnController spawnController)
    {
        this.spawnController = spawnController;
    }

    // Update is called once per frame
    void Update()
    {
        if (this.IsDead)
        {
            return;
        }

        //前に進ませる
        this.transform.localPosition += Vector3.back * Time.deltaTime;

        if(this.transform.localPosition.z < -2f)
        {
            var gameManager = FindObjectOfType<GameManager>();
            gameManager.GameOver();
        }
    }

    public void Death()
    {
        this.IsDead = true;
        this.spawnController.DeathDetected();

        //倒されたアニメーションを再生
        StartCoroutine(ScaleDown());
    }

    /// <summary>
    /// 小さくなるアニメーション
    /// </summary>
    /// <returns></returns>
    IEnumerator ScaleDown()
    {
        var startScale = this.transform.localScale;
        var scale = 1f;
        while (scale > 0f)
        {
            this.transform.localScale = scale * startScale;

            //1フレーム待つ
            yield return null;

            scale -= 0.02f;
        }

        Destroy(this.gameObject);
    }
}
