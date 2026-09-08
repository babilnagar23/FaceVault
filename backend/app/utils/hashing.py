"""Hashing utilities for refresh-token identifiers."""
import hashlib
import secrets


def generate_token(nbytes: int = 32) -> str:
    """Generate a cryptographically secure random token string."""
    return secrets.token_urlsafe(nbytes)


def hash_token(token: str) -> str:
    """Hash a token for storage (SHA-256). Never store raw refresh tokens.)"""
    return hashlib.sha256(token.encode()).hexdigest()


def verify_token_hash(token: str, token_hash: str) -> bool:
    return secrets.compare_digest(hash_token(token), token_hash)
