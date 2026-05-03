#!/bin/bash
# 测试测评历史API
curl -s -X GET "http://localhost:3000/api/v1/assessments/history/69f5f41787d57d76dc9250a4" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2OWU4YjY5OWI2NTdjM2U2MTE2YjQ3OTkiLCJ0eXBlIjoiYWNjZXNzIiwiaWF0IjoxNzc3NzI2NDg3LCJleHAiOjE3Nzc3MzM2ODd9.0my_HEFVyUltctumra1BNW-xBed9XZEEYlzOsICJW1w"