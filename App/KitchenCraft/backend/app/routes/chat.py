"""
Chat API routes
"""
from fastapi import APIRouter, HTTPException, status
from app.models.schemas import ChatRequest, ChatResponse, ErrorResponse
from app.services.ai_service import ai_service
from app.core.cache import cache_manager
import logging

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("/chat", response_model=ChatResponse)
async def chat_endpoint(request: ChatRequest):
    """
    Main chat endpoint for AI-powered cooking assistance
    
    - **prompt**: User's question or request (required)
    - **ingredients**: List of available ingredients (optional)
    - **user_id**: User ID for personalization (optional)
    - **context**: Additional context like preferences (optional)
    """
    try:
        logger.info(f"💬 Chat request: '{request.prompt[:50]}...' with {len(request.ingredients)} ingredients")
        
        # Generate AI response
        result = await ai_service.generate_response(
            prompt=request.prompt,
            ingredients=request.ingredients,
            context=request.context
        )
        
        response = ChatResponse(
            response=result["response"],
            tokens_used=result["tokens_used"],
            cached=result["cached"],
            processing_time=result["processing_time"],
            model=result["model"]
        )
        
        if result["cached"]:
            logger.info(f"✨ Returned cached response ({result['processing_time']:.3f}s)")
        else:
            logger.info(f"✅ Generated new response ({result['processing_time']:.3f}s, {result['tokens_used']} tokens)")
        
        return response
    
    except ValueError as e:
        logger.error(f"Validation error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Chat endpoint error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate response: {str(e)}"
        )


@router.post("/chat/clear-cache")
async def clear_cache():
    """Clear the response cache"""
    try:
        cache_manager.clear()
        return {"message": "Cache cleared successfully"}
    except Exception as e:
        logger.error(f"Error clearing cache: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/chat/cache-stats")
async def get_cache_stats():
    """Get cache statistics"""
    try:
        stats = cache_manager.get_stats()
        return stats
    except Exception as e:
        logger.error(f"Error getting cache stats: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
