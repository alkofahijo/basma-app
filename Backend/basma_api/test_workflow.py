from inference_sdk import InferenceHTTPClient

client = InferenceHTTPClient(
    api_url="http://localhost:9001",      # your local inference server
    api_key="CuuXFiPJOg9d38qSabF2",       # same key you used as ROBOFLOW_API_KEY
)

result = client.run_workflow(
    workspace_name="ahmad-i1hsy",         # exactly as shown in Roboflow
    workflow_id="image-analyize",         # watch spelling – must match Roboflow
    images={
        "image": r"C:\Users\USER\Desktop\test.jpg"   # REAL path to an image
    },
    use_cache=True,
)

print(result)
