import React from 'react'
import { render } from '@testing-library/react'
import App from './App'

test('renders table headers', () => {
  const { getByText } = render(<App />)
  expect(getByText('id')).toBeInTheDocument()
  expect(getByText('title')).toBeInTheDocument()
  expect(getByText('author')).toBeInTheDocument()
  expect(getByText('date')).toBeInTheDocument()
})

test('renders table rows', () => {
  const { getByText } = render(<App />)
  expect(getByText('Book 1')).toBeInTheDocument()
  expect(getByText('Author 1')).toBeInTheDocument()
  expect(getByText('2023-02-28')).toBeInTheDocument()
})
