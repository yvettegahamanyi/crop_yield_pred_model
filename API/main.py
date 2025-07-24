from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, validator
from typing import Literal
import joblib
import pandas as pd
import numpy as np
from pathlib import Path
import uvicorn

# Initialize FastAPI app
app = FastAPI(
    title="Crop Yield Prediction API",
    description="API for predicting crop yield based on environmental and agricultural factors",
    version="1.0.0",
    docs_url="/docs",  # Swagger UI documentation path
    redoc_url="/redoc"  # Alternative documentation
)

# Configure CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify actual origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load the trained model and feature names
try:
    model = joblib.load('API/best_model.pkl')
    feature_names = joblib.load('API/feature_names.pkl')
    print("Model and feature names loaded successfully")
except FileNotFoundError as e:
    print(f"Error loading model files: {e}")
    print("Please ensure 'best_model.pkl' and 'feature_names.pkl' are in the same directory")
    model = None
    feature_names = None

# Define valid areas and items based on your dataset
VALID_AREAS = [
    'Algeria', 'Angola', 'Benin', 'Botswana', 'Burkina Faso', 'Burundi',
    'Cabo Verde', 'Cameroon', 'Central African Republic', 'Chad', 'Comoros',
    'Congo (Brazzaville)', 'Congo (Kinshasa)', 'Djibouti', 'Egypt', 'Equatorial Guinea',
    'Eritrea', 'Eswatini', 'Ethiopia', 'Gabon', 'Gambia', 'Ghana', 'Guinea',
    'Guinea-Bissau', 'Ivory Coast', 'Kenya', 'Lesotho', 'Liberia', 'Libya',
    'Madagascar', 'Malawi', 'Mali', 'Mauritania', 'Mauritius', 'Morocco',
    'Mozambique', 'Namibia', 'Niger', 'Nigeria', 'Rwanda', 'Sao Tome and Principe',
    'Senegal', 'Seychelles', 'Sierra Leone', 'Somalia', 'South Africa', 'South Sudan',
    'Sudan', 'Tanzania', 'Togo', 'Tunisia', 'Uganda', 'Zambia', 'Zimbabwe'
]

VALID_ITEMS = [
    "Maize", "Potatoes", "Rice, paddy", "Sorghum", "Soybeans", "Wheat", 
    "Cassava", "Sweet potatoes", "Plantains and others", "Yams"
]


# Pydantic model for input validation with constraints
class CropYieldPredictionRequest(BaseModel):
    """
    Request model for crop yield prediction with data type constraints and validation
    """
    year: int = Field(
        ...,
        ge=1961,
        le=2030,
        description="Year of prediction (between 1961 and 2030)"
    )
    
    average_rain_fall_mm_per_year: float = Field(
        ..., 
        ge=0.0, 
        le=5000.0, 
        description="Average rainfall in mm per year (0-5000 mm)"
    )
    
    pesticides_tonnes: float = Field(
        ..., 
        ge=0.0, 
        le=1000000.0, 
        description="Pesticides used in tonnes (0-1,000,000 tonnes)"
    )
    
    avg_temp: float = Field(
        ..., 
        ge=-10.0, 
        le=50.0, 
        description="Average temperature in Celsius (-10 to 50°C)"
    )
    
    area: str = Field(
        ..., 
        description="Country/Area name"
    )
    
    item: str = Field(
        ..., 
        description="Crop type"
    )
    
    @validator('area')
    def validate_area(cls, v):
        if v not in VALID_AREAS:
            raise ValueError(f'Area must be one of: {", ".join(VALID_AREAS[:10])}... (and {len(VALID_AREAS)-10} more)')
        return v
    
    @validator('item')
    def validate_item(cls, v):
        if v not in VALID_ITEMS:
            raise ValueError(f'Item must be one of: {", ".join(VALID_ITEMS)}')
        return v
    
    class Config:
        json_schema_extra = {
            "example": {
                "year": 2006,
                "average_rain_fall_mm_per_year": 1180.0,
                "pesticides_tonnes": 88.0,
                "avg_temp": 23.95,
                "area": "Uganda",
                "item": "Plantains and others"
            }
        }

# Response model
class CropYieldPredictionResponse(BaseModel):
    """
    Response model for crop yield prediction
    """
    predicted_yield: float = Field(..., description="Predicted crop yield")
    input_parameters: dict = Field(..., description="Input parameters used for prediction")
    model_info: dict = Field(..., description="Information about the model used")

# Welcome check endpoint
@app.get("/", tags=["Welcome"])
async def root():
    """
    Welcome check endpoint
    """
    return {
        "message": "Welcome to Crop Yield Prediction API!",
    }

# prediction endpoint
@app.post("/predict", response_model=CropYieldPredictionResponse, tags=["Prediction"])
async def predict_crop_yield(request: CropYieldPredictionRequest):
    """
    Predict crop yield based on environmental and agricultural factors
    
    This endpoint uses a trained machine learning model to predict crop yield
    based on the following factors:
    - Year
    - Average rainfall (mm/year)
    - Pesticides usage (tonnes)
    - Average temperature (°C)
    - Area/Country
    - Crop type
    
    Returns the predicted yield along with input parameters and model information.
    """
    
    # Check if model is loaded
    if model is None or feature_names is None:
        raise HTTPException(
            status_code=500, 
            detail="Model not loaded. Please ensure model files are available."
        )
    
    try:
        # Create input dataframe with numerical features only
        input_data = pd.DataFrame({
            'Year': [request.year],
            'average_rain_fall_mm_per_year': [request.average_rain_fall_mm_per_year],
            'pesticides_tonnes': [request.pesticides_tonnes],
            'avg_temp': [request.avg_temp]
        })
        
        # Initialize all features with 0 (this ensures we have all required columns)
        for feature in feature_names:
            if feature not in input_data.columns:
                input_data[feature] = 0
        
        # Set the appropriate area column to 1 (one-hot encoding)
        area_column = f'Area_{request.area}'
        if area_column in feature_names:
            input_data[area_column] = 1
        
        # Set the appropriate item column to 1 (one-hot encoding)
        item_column = f'Item_{request.item}'
        if item_column in feature_names:
            input_data[item_column] = 1
        
        # Reorder columns to match training data exactly
        input_data = input_data[feature_names]
        
        # Convert to numpy array to avoid feature name mismatch issues
        input_array = input_data.values
        
        # Make prediction
        prediction = model.predict(input_array)[0]
        
        # Prepare response
        response = CropYieldPredictionResponse(
            predicted_yield=float(prediction),
            input_parameters={
                "year": request.year,
                "average_rain_fall_mm_per_year": request.average_rain_fall_mm_per_year,
                "pesticides_tonnes": request.pesticides_tonnes,
                "avg_temp": request.avg_temp,
                "area": request.area,
                "item": request.item
            },
            model_info={
                "model_type": str(type(model).__name__),
                "features_used": len(feature_names),
                "prediction_unit": "yield_value"
            }
        )
        
        return response
        
    except Exception as e:
        raise HTTPException(
            status_code=400, 
            detail=f"Error making prediction: {str(e)}"
        )

# Run the application
if __name__ == "__main__":
    uvicorn.run(
        "main:app",  # Replace "main" with your actual filename if different
        host="0.0.0.0",
        port=8000,
        reload=True
    )