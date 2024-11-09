





----



CREATE
  (dan:Person {name: 'Dan',     age: 18, experience: 63, hipster: 0}),
  (annie:Person {name: 'Annie', age: 12, experience: 5, hipster: 0}),
  (matt:Person {name: 'Matt',   age: 22, experience: 42, hipster: 0}),
  (jeff:Person {name: 'Jeff',   age: 51, experience: 12, hipster: 0}),
  (brie:Person {name: 'Brie',   age: 31, experience: 6, hipster: 0}),
  (elsa:Person {name: 'Elsa',   age: 65, experience: 23, hipster: 1}),
  (john:Person {name: 'John',   age: 4, experience: 100, hipster: 0}),
  (apple:Fruit {name: 'Apple',   tropical: 0, sourness: 0.3, sweetness: 0.6}),
  (banana:Fruit {name: 'Banana', tropical: 1, sourness: 0.1, sweetness: 0.9}),
  (mango:Fruit {name: 'Mango',   tropical: 1, sourness: 0.3, sweetness: 1.0}),
  (plum:Fruit {name: 'Plum',    tropical: 0, sourness: 0.5, sweetness: 0.8}),

  (dan)-[:LIKES]->(apple),
  (annie)-[:LIKES]->(banana),
  (matt)-[:LIKES]->(mango),
  (jeff)-[:LIKES]->(mango),
  (brie)-[:LIKES]->(banana),
  (elsa)-[:LIKES]->(plum),
  (john)-[:LIKES]->(plum),

  (dan)-[:KNOWS]->(annie),
  (dan)-[:KNOWS]->(matt),
  (annie)-[:KNOWS]->(matt),
  (annie)-[:KNOWS]->(jeff),
  (annie)-[:KNOWS]->(brie),
  (matt)-[:KNOWS]->(brie),
  (brie)-[:KNOWS]->(elsa),
  (brie)-[:KNOWS]->(jeff),
  (john)-[:KNOWS]->(jeff);


MATCH (source)
OPTIONAL MATCH (source)-[r]->(target)
RETURN gds.graph.project(
  'persons',
  source,
  target,
  {
    sourceNodeLabels: labels(source),
    targetNodeLabels: labels(target),
    sourceNodeProperties: {
      age: coalesce(source.age, 0.0),
      experience: coalesce(source.experience, 0.0),
      hipster: coalesce(source.hipster, 0.0),
      tropical: coalesce(source.tropical, 0.0),
      sourness: coalesce(source.sourness, 0.0),
      sweetness: coalesce(source.sweetness, 0.0)
    },
    targetNodeProperties: {
      age: coalesce(target.age, 0.0),
      experience: coalesce(target.experience, 0.0),
      hipster: coalesce(target.hipster, 0.0),
      tropical: coalesce(target.tropical, 0.0),
      sourness: coalesce(target.sourness, 0.0),
      sweetness: coalesce(target.sweetness, 0.0)
    },
    relationshipType: type(r)
  },
  { undirectedRelationshipTypes: ['KNOWS', 'LIKES'] }
)

CALL gds.scaleProperties.mutate('persons', {
  nodeProperties: ['experience'],
  scaler: 'Minmax',
  mutateProperty: 'experience_scaled'
}) YIELD nodePropertiesWritten


CALL gds.hashgnn.stream('persons',
  {
    nodeLabels: ['Person'],
    iterations: 3,
    embeddingDensity: 4,
    generateFeatures: {dimension: 8, densityLevel: 2},
    randomSeed: 42
  }
)
YIELD nodeId, embedding
RETURN gds.util.asNode(nodeId).name AS person, embedding
ORDER BY person


CALL gds.hashgnn.mutate(
  'persons',
  {
    mutateProperty: 'embedding2',
    heterogeneous: true,
    iterations: 5, // Increase iterations for better convergence
    embeddingDensity: 8, // Increase embedding density for richer embeddings
    binarizeFeatures: {dimension: 10, threshold: 0.1}, // Adjust binarization for more granularity
    featureProperties: ['experience_scaled', 'sourness', 'sweetness', 'tropical', 'hipster'], // Add more features for diversity
    randomSeed: 42
  }
)
YIELD nodePropertiesWritten


CALL gds.hashgnn.stream('persons',
  {
    heterogeneous: true,
    iterations: 2,
    embeddingDensity: 4,
    binarizeFeatures: {dimension: 6, threshold: 0.2},
    featureProperties: ['experience_scaled', 'sourness', 'sweetness', 'tropical'],
    outputDimension: 4,
    randomSeed: 42
  }
)
YIELD nodeId, embedding
RETURN gds.util.asNode(nodeId).name AS name, embedding
ORDER BY name



CALL gds.graph.nodeProperties.write('persons', ['embedding'])
YIELD propertiesWritten


MATCH (p1:Person {name: 'Elsa'}), (p2:Person)
WHERE p1 <> p2
WITH p1.embedding AS vector1, p2.embedding AS vector2, p2.name AS otherPerson
RETURN otherPerson, gds.similarity.cosine(vector1, vector2) AS cosineSimilarity
ORDER BY cosineSimilarity DESC


