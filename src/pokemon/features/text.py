import pandas as pd
from neo4j_graphrag.llm import LLMResponse, OpenAILLM
from neo4j_graphrag.embeddings import OpenAIEmbeddings


# embeder = OpenAIEmbeddings(
#     base_url="http://localhost:11434/v1",
#     api_key="ollama",
#     model="snowflake-arctic-embed:latest",
# )

# llm = OpenAILLM(
#     base_url="http://localhost:11434/v1",
#     model_name="llama3",
#     api_key="ollama",
# )

# def generate_description(question:str) -> str:
#     res: LLMResponse = llm.invoke(question)
#     return res.content

class TextProcessor():

    def __init__(self, embedder) -> None:
        self.embedder = embedder
        

    def clean_height_weight(self, df: pd.DataFrame) -> pd.DataFrame:
        # Remove units and convert to float
        df['Height'] = df['Height'].str.extract(r'([\d.]+)').astype(float)
        df['Weight'] = df['Weight'].str.extract(r'([\d.]+)').astype(float)
        return df
    
    def get_embeddings(self, text:str):
        embeddings = self.embedder.embed_query(text)
        return embeddings

    def generate_pokemon_description_embeddings(self, pokemon_df):
        embeddings = []
        for _, row in pokemon_df.iterrows():
            embedding = self.get_embeddings(row['Description'])
            embeddings.append(embedding)
        return embeddings

    def generate_description(self, row : pd.Series) -> str:
        json_data = row.to_json()
        return json_data


    def generate_pokemon_descriptions(self, pokemon_df: pd.DataFrame):
        descriptions = []
        for _, row in pokemon_df.iterrows():
            
            description = self.generate_description(row)

            descriptions.append(description)
        return descriptions


    def run(self, df: pd.DataFrame) -> pd.DataFrame:
        df = self.clean_height_weight(df)
        df['Description'] = self.generate_pokemon_descriptions(df)
        df['vectorProperty'] = self.generate_pokemon_description_embeddings(df)

        return df

