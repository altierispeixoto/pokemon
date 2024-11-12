from transformers import CLIPProcessor, CLIPModel
from PIL import Image
import torch

model_name = "openai/clip-vit-base-patch32"
model = CLIPModel.from_pretrained(model_name)
processor = CLIPProcessor.from_pretrained(model_name)

class ImageProcessor():

    def __init__(self) -> None:
        pass

    def extract_image_embedding(self, pokemon_name):
        image_path = f"../data/pokemon_db/images/{pokemon_name}/{pokemon_name}_new.png"
        try:
            image = Image.open(image_path).convert("RGB")
            inputs = processor(images=image, return_tensors="pt", padding=True)
            
            with torch.no_grad():
                outputs = model.get_image_features(**inputs)
            
            # Normalize the embedding
            embedding = outputs.squeeze()
            embedding = embedding / embedding.norm(dim=-1, keepdim=True)
            return embedding.tolist()
        except FileNotFoundError:
            print(f"Image not found for {pokemon_name}. Continuing to next.")
            return None
        
    def run(self, df):

        df['PictureEmbeddings'] = df['PokemonFile'].apply(lambda x : self.extract_image_embedding(x))
        return df
