using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;

/// <summary>
/// UIの制御
/// </summary>
public class UIController : MonoBehaviour
{
    [SerializeField] GameObject startButton;
    [SerializeField] GameObject scoreObject;
    [SerializeField] GameObject gameOverObject;
    [SerializeField] TextMeshProUGUI scoreText;

    /// <summary>
    /// タイトル画面の表示非表示
    /// </summary>
    /// <param name="visible"></param>
    public void VisibleTitle(bool visible)
    {
        this.startButton.SetActive(visible);
    }

    /// <summary>
    /// スコアの表示非表示
    /// </summary>
    /// <param name="visible"></param>
    public void VisibleScore(bool visible)
    {
        this.scoreObject.SetActive(visible);
    }

    /// <summary>
    /// スコアの設定
    /// </summary>
    /// <param name="score"></param>
    public void SetScore(int score)
    {
        this.scoreText.text = score.ToString();
    }

    /// <summary>
    /// ゲームオーバー表示
    /// </summary>
    /// <param name="visible"></param>
    public void VisibleGameOver(bool visible)
    {
        this.gameOverObject.SetActive(visible);
    }
}
