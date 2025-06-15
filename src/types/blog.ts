export type Category = {
    id: string
    name: string
    slug: string
  }
  
  export type Author = {
    id: string
    name: string
    avatar?: string
  }
  
  export type BlogPost = {
    id: string
    title: string
    slug: string
    excerpt: string
    content: string
    publishedAt: string
    readingTime: string
    category: Category
    author: Author
  }
  