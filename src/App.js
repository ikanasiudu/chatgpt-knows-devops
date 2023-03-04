import { useState, useEffect } from 'react'

// Define your in-memory database
const database = [
  { id: 1, title: 'Book 1', author: 'Author 1', date: '2023-02-28' },
  { id: 2, title: 'Book 2', author: 'Author 2', date: '2023-02-27' },
  { id: 3, title: 'Book 3', author: 'Author 3', date: '2023-02-26' }
]

// Define the schema for your table of contents
const schema = ['id', 'title', 'author', 'date']

function App () {
  const [data, setData] = useState([])

  useEffect(() => {
    // Fetch the data from the database and update the state of the component
    setData(database)
  }, [])

  return (
    <table className='table table-striped table-hover'>
      <thead className='thead-dark'>
        <tr>
          {' '}
          {schema.map(header => (
            <th key={header}> {header} </th>
          ))}{' '}
        </tr>{' '}
      </thead>{' '}
      <tbody>
        {' '}
        {data.map(item => (
          <tr key={item.id}>
            {' '}
            {schema.map(field => (
              <td key={field}> {item[field]} </td>
            ))}{' '}
          </tr>
        ))}{' '}
      </tbody>{' '}
    </table>
  )
}

export default App
