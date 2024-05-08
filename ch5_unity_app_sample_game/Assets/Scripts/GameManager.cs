using System.Collections.Generic;
using Unity.PolySpatial.InputDevices;
using UnityEngine;
using UnityEngine.InputSystem.EnhancedTouch;
using UnityEngine.InputSystem.LowLevel;
using Touch = UnityEngine.InputSystem.EnhancedTouch.Touch;

/// <summary>
/// ゲーム全体の制御
/// </summary>
public class GameManager : MonoBehaviour
{
    [SerializeField] SpawnController spawnController;
    [SerializeField] UIController uiController;

    enum State
    {
        Title,
        InGame,
        GameOver
    }
    State state = State.Title;

    int score = 0;

    void Start()
    {
        EnhancedTouchSupport.Enable();
    }

    void Update()
    {
        CheckTouch();
    }

    void CheckTouch()
    {
        foreach (var touch in Touch.activeTouches)
        {
            var spatialPointerState = EnhancedSpatialPointerSupport.GetPointerState(touch);

            if (spatialPointerState.Kind == SpatialPointerKind.Touch)
                continue;

            var pieceObject = spatialPointerState.targetObject;
            if (pieceObject != null)
            {
                switch (this.state)
                {
                    case State.Title:
                        //タップしたオブジェクトがStartButtonだったらInGameに進める
                        if(pieceObject.name == "StartButton")
                        {
                            StartGame();
                        }
                        break;
                    case State.InGame:
                        //タップしたオブジェクトが敵だったらスコアを加算する
                        if (pieceObject.TryGetComponent<Enemy>(out var enemy))
                        {
                            if (enemy.IsDead == false)
                            {
                                enemy.Death();
                                this.score++;
                                this.uiController.SetScore(this.score);
                            }
                        }
                        break;
                    case State.GameOver:
                        //タップしたオブジェクトがRetryButtonだったらシーンをロードし直して最初に戻る
                        if (pieceObject.name == "RetryButton")
                        {
                            UnityEngine.SceneManagement.SceneManager.LoadScene(0);
                        }
                        break;
                    default:
                        Debug.LogWarning("Unknown State:" + this.state);
                        break;
                }
            }
        }
    }

    /// <summary>
    /// ゲーム開始時処理
    /// </summary>
    void StartGame()
    {
        this.spawnController.StartSpawn();
        this.uiController.VisibleTitle(false);
        this.uiController.VisibleScore(true);
        this.state = State.InGame;
    }

    /// <summary>
    /// ゲームオーバーにする(Enemyから呼ばれる)
    /// </summary>
    public void GameOver()
    {
        if(this.state == State.InGame)
        {
            this.spawnController.StopSpawn();
            this.uiController.VisibleGameOver(true);
            this.state = State.GameOver;
        }
    }
}
