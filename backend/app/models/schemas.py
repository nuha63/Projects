"""
Pydantic models for request/response validation
"""
from pydantic import BaseModel, Field, validator
from typing import List, Optional, Dict, Any
from datetime import datetime


class ChatRequest(BaseModel):
    """Chat request model"""
    prompt: str = Field(..., min_length=1, max_length=2000, description="User's question or request")
    ingredients: List[str] = Field(default=[], description="List of available ingredients")
    user_id: Optional[str] = Field(None, description="User ID for personalization")
    context: Optional[Dict[str, Any]] = Field(None, description="Additional context (preferences, history)")
    
    @validator('ingredients')
    def clean_ingredients(cls, v):
        """Clean and deduplicate ingredients"""
        return list(set([i.strip().lower() for i in v if i.strip()]))
    
    @validator('prompt')
    def clean_prompt(cls, v):
        """Clean prompt"""
        return v.strip()


class ChatResponse(BaseModel):
    """Chat response model"""
    response: str = Field(..., description="AI-generated response")
    tokens_used: int = Field(0, description="Number of tokens consumed")
    cached: bool = Field(False, description="Whether response was from cache")
    processing_time: float = Field(0.0, description="Processing time in seconds")
    model: str = Field("", description="AI model used")
    timestamp: datetime = Field(default_factory=datetime.now)


class ErrorResponse(BaseModel):
    """Error response model"""
    error: str = Field(..., description="Error message")
    detail: Optional[str] = Field(None, description="Detailed error information")
    code: str = Field("INTERNAL_ERROR", description="Error code")


class HealthResponse(BaseModel):
    """Health check response"""
    status: str = Field("ok", description="Service status")
    version: str = Field("1.0.0", description="API version")
    environment: str = Field("development", description="Environment")
    api_configured: bool = Field(False, description="Whether API keys are configured")
    cache_stats: Optional[Dict[str, Any]] = Field(None, description="Cache statistics")
