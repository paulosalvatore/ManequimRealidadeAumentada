using UnityEngine;

// This script will rotate and scale the GameObject based on finger gestures
public class rotate : MonoBehaviour
{
	protected virtual void LateUpdate()
	{
		// This will rotate the current transform based on a multi finger twist gesture
		Lean.LeanTouch.RotateObject(transform, Lean.LeanTouch.DragDelta);
	}
}