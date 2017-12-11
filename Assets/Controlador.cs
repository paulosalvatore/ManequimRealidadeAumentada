using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class Controlador : MonoBehaviour
{
	public GameObject canvas;

	public GameObject modelo1;
	public GameObject modelo1Prefab;

	public GameObject modelo2;
	public GameObject modelo2Prefab;

	public float multiplicadorEscala;

	private Vector3 escalaModelo1;
	private Vector3 escalaModelo2;

	private void Start()
	{
		escalaModelo1 = new Vector3(
			PlayerPrefs.GetFloat("EscalaModelo1_X", 1),
			PlayerPrefs.GetFloat("EscalaModelo1_Y", 1),
			PlayerPrefs.GetFloat("EscalaModelo1_Z", 1)
		);

		escalaModelo2 = new Vector3(
			PlayerPrefs.GetFloat("EscalaModelo2_X", 1),
			PlayerPrefs.GetFloat("EscalaModelo2_Y", 1),
			PlayerPrefs.GetFloat("EscalaModelo2_Z", 1)
		);

		AtualizarEscalaModelos();
	}

	private void Update()
	{
		if (Input.GetKeyDown(KeyCode.Escape))
		{
			AlterarExibicaoCanvas();
		}
	}

	private void AlterarExibicaoCanvas()
	{
		canvas.SetActive(!canvas.activeSelf);
	}

	public void ReiniciarCena()
	{
		SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);
	}

	public void AumentarEscalaModelo1()
	{
		escalaModelo1 += Vector3.one * multiplicadorEscala;

		AtualizarEscalaModelos();
	}

	public void DiminuirEscalaModelo1()
	{
		escalaModelo1 -= Vector3.one * multiplicadorEscala;

		AtualizarEscalaModelos();
	}

	public void AumentarEscalaModelo2()
	{
		escalaModelo2 += Vector3.one * multiplicadorEscala;

		AtualizarEscalaModelos();
	}

	public void DiminuirEscalaModelo2()
	{
		escalaModelo2 -= Vector3.one * multiplicadorEscala;

		AtualizarEscalaModelos();
	}

	private void AtualizarEscalaModelos()
	{
		DesativarCloth(modelo1);
		DesativarCloth(modelo2);

		modelo1.SetActive(false);
		modelo2.SetActive(false);

		modelo1.transform.localScale = escalaModelo1;
		modelo2.transform.localScale = escalaModelo2;

		modelo1.SetActive(true);
		modelo2.SetActive(true);

		AtivarCloth(modelo1);
		AtivarCloth(modelo2);

		PlayerPrefs.SetFloat("EscalaModelo1_X", escalaModelo1.x);
		PlayerPrefs.SetFloat("EscalaModelo1_Y", escalaModelo1.y);
		PlayerPrefs.SetFloat("EscalaModelo1_Z", escalaModelo1.z);

		PlayerPrefs.SetFloat("EscalaModelo2_X", escalaModelo2.x);
		PlayerPrefs.SetFloat("EscalaModelo2_Y", escalaModelo2.y);
		PlayerPrefs.SetFloat("EscalaModelo2_Z", escalaModelo2.z);
	}

	private void DesativarCloth(GameObject modelo)
	{
		AlterarEstadoCloth(modelo, false);
	}

	private void AtivarCloth(GameObject modelo)
	{
		AlterarEstadoCloth(modelo, true);
	}

	private void AlterarEstadoCloth(GameObject objeto, bool estado)
	{
		Cloth[] cloths = objeto.GetComponentsInChildren<Cloth>();

		foreach (Cloth cloth in cloths)
			cloth.enabled = estado;
	}
}
