"""
AI Service - Handles all AI/LLM interactions
"""
import httpx
import json
import logging
from typing import Optional, Dict, Any, List
from app.core.config import settings
from app.core.cache import cache_manager

logger = logging.getLogger(__name__)


class AIService:
    """Service for AI/LLM operations"""
    
    def __init__(self):
        self.client = httpx.AsyncClient(timeout=settings.API_TIMEOUT)
    
    async def close(self):
        """Close HTTP client"""
        await self.client.aclose()
    
    def _build_enhanced_prompt(
        self, 
        user_prompt: str, 
        ingredients: List[str],
        context: Optional[Dict[str, Any]] = None
    ) -> str:
        """
        Build an enhanced prompt with context and structure
        
        Args:
            user_prompt: User's original question
            ingredients: Available ingredients
            context: Additional context (preferences, history, etc.)
        
        Returns:
            Enhanced prompt string
        """
        # Base system message
        system_msg = """You are a helpful, friendly cooking assistant for KitchenCraft app. Your goal is to help users create delicious meals."""
        
        # Add ingredient context
        ingredients_text = ""
        if ingredients:
            ingredients_text = f"\n\n📦 Available ingredients: {', '.join(ingredients)}"
        
        # Add user context if available
        context_text = ""
        if context:
            dietary_prefs = context.get('dietary_preferences', [])
            if dietary_prefs:
                context_text += f"\n🥗 Dietary preferences: {', '.join(dietary_prefs)}"
            
            cuisine_prefs = context.get('cuisine_preferences', [])
            if cuisine_prefs:
                context_text += f"\n🌍 Preferred cuisines: {', '.join(cuisine_prefs)}"
            
            avoid = context.get('allergies', [])
            if avoid:
                context_text += f"\n⚠️ Must avoid: {', '.join(avoid)}"
        
        # Build full prompt with structure
        full_prompt = f"""{system_msg}
{context_text}
{ingredients_text}

👤 User question: {user_prompt}

📝 Instructions:
- If suggesting a recipe, provide a clear title, ingredient list (mark available ones), numbered steps, and cooking time
- If ingredients are missing, suggest reasonable substitutions
- Keep responses concise but helpful (300-500 words max)
- Use friendly, encouraging tone
- Focus on practical, achievable recipes

Please provide a helpful response:"""
        
        return full_prompt
    
    async def generate_response(
        self,
        prompt: str,
        ingredients: List[str],
        context: Optional[Dict[str, Any]] = None,
        use_cache: bool = True
    ) -> Dict[str, Any]:
        """
        Generate AI response using Groq API with caching
        
        Args:
            prompt: User's question
            ingredients: Available ingredients
            context: Additional context
            use_cache: Whether to use cache
        
        Returns:
            Dict with response, tokens_used, cached, model
        """
        import time
        start_time = time.time()
        
        # Check cache first
        if use_cache and settings.CACHE_ENABLED:
            cached = cache_manager.get(prompt, ingredients)
            if cached:
                return {
                    "response": cached,
                    "tokens_used": 0,
                    "cached": True,
                    "processing_time": time.time() - start_time,
                    "model": settings.GROQ_MODEL
                }
        
        # Build enhanced prompt
        enhanced_prompt = self._build_enhanced_prompt(prompt, ingredients, context)
        
        # Call Groq API
        try:
            response_data = await self._call_groq_api(enhanced_prompt)
            ai_response = response_data["response"]
            tokens = response_data["tokens"]
            
            # Cache the response
            if use_cache and settings.CACHE_ENABLED:
                cache_manager.set(prompt, ingredients, ai_response)
            
            return {
                "response": ai_response,
                "tokens_used": tokens,
                "cached": False,
                "processing_time": time.time() - start_time,
                "model": settings.GROQ_MODEL
            }
        
        except Exception as e:
            logger.error(f"Error generating AI response: {str(e)}")
            raise
    
    async def _call_groq_api(self, prompt: str) -> Dict[str, Any]:
        """
        Call Groq API
        
        Args:
            prompt: The full prompt to send
        
        Returns:
            Dict with response and tokens
        
        Raises:
            Exception if API call fails
        """
        if not settings.GROQ_API_KEY:
            raise ValueError("GROQ_API_KEY not configured")
        
        logger.info("🤖 Calling Groq API...")
        
        try:
            response = await self.client.post(
                settings.GROQ_API_URL,
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {settings.GROQ_API_KEY}"
                },
                json={
                    "model": settings.GROQ_MODEL,
                    "messages": [
                        {"role": "user", "content": prompt}
                    ],
                    "temperature": 0.7,
                    "max_tokens": 1000
                }
            )
            
            if response.status_code != 200:
                error_detail = response.text
                logger.error(f"Groq API error: {response.status_code} - {error_detail}")
                raise Exception(f"Groq API error: {response.status_code}")
            
            data = response.json()
            ai_response = data["choices"][0]["message"]["content"]
            tokens = data.get("usage", {}).get("total_tokens", 0)
            
            logger.info(f"✅ Groq API response received ({tokens} tokens)")
            
            return {
                "response": ai_response,
                "tokens": tokens
            }
        
        except httpx.TimeoutException:
            logger.error("Groq API timeout")
            raise Exception("AI service timeout - please try again")
        except httpx.RequestError as e:
            logger.error(f"Network error: {str(e)}")
            raise Exception("Network error - please check your connection")
        except Exception as e:
            logger.error(f"Unexpected error calling Groq API: {str(e)}")
            raise


# Global AI service instance
ai_service = AIService()
