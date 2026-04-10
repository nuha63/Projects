"""
Simple in-memory cache manager for API responses
"""
import hashlib
import json
import time
from typing import Optional, Dict, Any
from collections import OrderedDict
import logging

logger = logging.getLogger(__name__)


class CacheManager:
    """Simple LRU cache for API responses"""
    
    def __init__(self, max_size: int = 100, ttl: int = 3600):
        """
        Initialize cache manager
        
        Args:
            max_size: Maximum number of cached items
            ttl: Time to live in seconds (default 1 hour)
        """
        self.cache: OrderedDict = OrderedDict()
        self.max_size = max_size
        self.ttl = ttl
        self.hits = 0
        self.misses = 0
    
    def _generate_key(self, prompt: str, ingredients: list) -> str:
        """Generate cache key from prompt and ingredients"""
        data = {
            "prompt": prompt.lower().strip(),
            "ingredients": sorted([i.lower().strip() for i in ingredients])
        }
        content = json.dumps(data, sort_keys=True)
        return hashlib.md5(content.encode()).hexdigest()
    
    def get(self, prompt: str, ingredients: list) -> Optional[str]:
        """Get cached response if available and not expired"""
        key = self._generate_key(prompt, ingredients)
        
        if key in self.cache:
            cached_data = self.cache[key]
            
            # Check if expired
            if time.time() - cached_data['timestamp'] > self.ttl:
                del self.cache[key]
                self.misses += 1
                logger.info(f"Cache expired for key: {key[:8]}...")
                return None
            
            # Move to end (mark as recently used)
            self.cache.move_to_end(key)
            self.hits += 1
            logger.info(f"✨ Cache hit! Key: {key[:8]}...")
            return cached_data['response']
        
        self.misses += 1
        return None
    
    def set(self, prompt: str, ingredients: list, response: str):
        """Cache a response"""
        key = self._generate_key(prompt, ingredients)
        
        # Remove oldest if at capacity
        if len(self.cache) >= self.max_size and key not in self.cache:
            removed_key = next(iter(self.cache))
            del self.cache[removed_key]
            logger.info(f"Cache full, removed oldest: {removed_key[:8]}...")
        
        self.cache[key] = {
            'response': response,
            'timestamp': time.time()
        }
        logger.info(f"💾 Cached response for key: {key[:8]}...")
    
    def clear(self):
        """Clear all cache"""
        self.cache.clear()
        self.hits = 0
        self.misses = 0
        logger.info("🗑️ Cache cleared")
    
    def get_stats(self) -> Dict[str, Any]:
        """Get cache statistics"""
        total_requests = self.hits + self.misses
        hit_rate = (self.hits / total_requests * 100) if total_requests > 0 else 0
        
        return {
            "size": len(self.cache),
            "max_size": self.max_size,
            "hits": self.hits,
            "misses": self.misses,
            "hit_rate": f"{hit_rate:.2f}%",
            "ttl_seconds": self.ttl
        }


# Global cache instance
cache_manager = CacheManager()
