# Sample Python file for testing syntax highlighting
import os
import sys
from typing import List, Dict

class TestClass:
    """A test class for demonstrating Python syntax highlighting"""
    
    def __init__(self, name: str):
        self.name = name
        self.data = []
    
    @property
    def count(self) -> int:
        """Get the number of items"""
        return len(self.data)
    
    @staticmethod
    def utility_function(value: str) -> str:
        # This is a comment
        return value.upper()

def main():
    """Main function"""
    test_obj = TestClass("example")
    
    # Process some data
    for i in range(10):
        test_obj.data.append(f"item_{i}")
    
    if test_obj.count > 5:
        print(f"We have {test_obj.count} items")
    else:
        print("Not enough items")

if __name__ == "__main__":
    main()