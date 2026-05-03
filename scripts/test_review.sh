#!/bin/bash
# 测试review类型测评
curl -s -X POST "http://localhost:3000/api/v1/assessments/start" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2OWU4YjY5OWI2NTdjM2U2MTE2YjQ3OTkiLCJ0eXBlIjoiYWNjZXNzIiwiaWF0IjoxNzc3NzI2NDg3LCJleHAiOjE3Nzc3MzM2ODd9.0my_HEFVyUltctumra1BNW-xBed9XZEEYlzOsICJW1w" \
  -H "Content-Type: application/json" \
  -d '{"childId":"69f5f41787d57d76dc9250a4","type":"review","bookId":"69f5f057a57a7dcd6cb03b20","questionCount":3}'