import type { BlogPost, Category } from "@/types/blog"

export const categories: Category[] = [
  { id: "1", name: "AI Research", slug: "ai-research" },
  { id: "2", name: "Technology", slug: "technology" },
  { id: "3", name: "Development", slug: "development" },
  { id: "4", name: "Design", slug: "design" },
  { id: "5", name: "Business", slug: "business" },
]

export const blogPosts: BlogPost[] = [
  {
    id: "1",
    title: "The Future of AI in Software Development",
    slug: "future-ai-software-development",
    excerpt:
      "Exploring how artificial intelligence is transforming the way we build, test, and deploy software applications.",
    content: `
# The Future of AI in Software Development

Artificial intelligence is rapidly transforming the software development landscape, introducing new tools and methodologies that are changing how developers work.

## Code Generation and Assistance

Modern AI tools can now generate code based on natural language descriptions, helping developers work faster and focus on higher-level problems rather than implementation details.

- **Autocomplete and suggestions**: AI-powered IDEs can predict what you're trying to code and offer relevant suggestions.
- **Bug detection**: AI systems can identify potential bugs before code is even committed.
- **Refactoring assistance**: AI can suggest code improvements and help maintain cleaner codebases.

## Testing and Quality Assurance

AI is revolutionizing how we test software:

1. Automated test generation based on code analysis
2. Intelligent test prioritization to focus on areas most likely to have issues
3. Visual regression testing that can detect subtle UI changes

## Deployment and Operations

DevOps processes are becoming smarter with AI:

- Predictive scaling based on traffic patterns
- Anomaly detection in system performance
- Automated incident response

## Ethical Considerations

As we integrate AI more deeply into development processes, we must consider:

- Ensuring AI tools don't perpetuate biases in code
- Maintaining developer skills even as automation increases
- Addressing security concerns in AI-generated code

## Conclusion

The future of software development will be a partnership between human creativity and AI capabilities. Developers who learn to effectively collaborate with AI tools will have a significant advantage in productivity and innovation.
    `,
    publishedAt: "2023-06-15",
    readingTime: "5 min read",
    category: categories[0],
    author: {
      id: "1",
      name: "Alex Johnson",
      avatar: "/placeholder.svg?height=40&width=40",
    },
  },
  {
    id: "2",
    title: "Building Accessible Web Applications",
    slug: "building-accessible-web-applications",
    excerpt:
      "Learn the essential practices for creating web applications that are accessible to all users, including those with disabilities.",
    content: `
# Building Accessible Web Applications

Creating accessible web applications isn't just a legal requirement in many jurisdictions—it's a fundamental aspect of good design that ensures your products can be used by everyone, regardless of their abilities.

## Understanding Web Accessibility

Web accessibility means designing and developing websites and applications that people with disabilities can perceive, understand, navigate, and interact with. This includes accommodations for:

- Visual impairments
- Hearing impairments
- Motor limitations
- Cognitive disabilities

## Key Accessibility Principles

### Perceivable Content

- Provide text alternatives for non-text content
- Create content that can be presented in different ways
- Make it easier for users to see and hear content

### Operable Interface

- Make all functionality available from a keyboard
- Give users enough time to read and use content
- Do not use content that causes seizures or physical reactions
- Help users navigate and find content

### Understandable Information

- Make text readable and understandable
- Make content appear and operate in predictable ways
- Help users avoid and correct mistakes

### Robust Content

- Maximize compatibility with current and future tools

## Practical Implementation Tips

1. Use semantic HTML elements that accurately describe their content
2. Include proper alt text for images
3. Ensure sufficient color contrast
4. Design focus indicators for keyboard navigation
5. Create accessible forms with proper labels
6. Test with screen readers and keyboard navigation

## Testing Accessibility

Regular testing is crucial for maintaining accessibility:

- Automated testing tools like Axe or Lighthouse
- Manual testing with keyboard navigation
- Screen reader testing
- User testing with people who have disabilities

## Conclusion

Building accessible applications takes practice and awareness, but the benefits extend beyond compliance—they create better experiences for all users. Start incorporating these practices into your development workflow today.
    `,
    publishedAt: "2023-05-22",
    readingTime: "7 min read",
    category: categories[2],
    author: {
      id: "2",
      name: "Maya Patel",
      avatar: "/placeholder.svg?height=40&width=40",
    },
  },
  {
    id: "3",
    title: "Optimizing React Performance",
    slug: "optimizing-react-performance",
    excerpt:
      "Discover techniques and best practices to improve the performance of your React applications for better user experience.",
    content: `
# Optimizing React Performance

React applications can suffer from performance issues as they grow in complexity. This article explores practical techniques to optimize your React applications for better speed and user experience.

## Understanding React Rendering

Before optimizing, it's important to understand how React's rendering process works:

- Component rendering
- Virtual DOM diffing
- Reconciliation process

## Common Performance Issues

Several issues commonly affect React application performance:

1. Unnecessary re-renders
2. Large bundle sizes
3. Unoptimized images and assets
4. Expensive calculations in render methods
5. Memory leaks

## Optimization Techniques

### Memoization

Use React's built-in memoization tools to prevent unnecessary re-renders:

\`\`\`jsx
// Using React.memo for functional components
const MemoizedComponent = React.memo(MyComponent);

// Using useMemo for expensive calculations
const expensiveValue = useMemo(() => computeExpensiveValue(a, b), [a, b]);

// Using useCallback for function references
const memoizedCallback = useCallback(() => doSomething(a, b), [a, b]);
\`\`\`

### Code Splitting

Reduce your initial bundle size with code splitting:

\`\`\`jsx
// Using dynamic imports
const LazyComponent = React.lazy(() => import('./LazyComponent'));

// With Suspense
<Suspense fallback={<Loading />}>
  <LazyComponent />
</Suspense>
\`\`\`

### Virtual List Rendering

For long lists, use virtualization:

\`\`\`jsx
import { FixedSizeList } from 'react-window';

const MyList = ({ items }) => (
  <FixedSizeList
    height={500}
    width={500}
    itemSize={50}
    itemCount={items.length}
    itemData={items}
  >
    {({ index, style, data }) => (
      <div style={style}>
        {data[index].name}
      </div>
    )}
  </FixedSizeList>
);
\`\`\`

### Optimizing Context

Avoid putting too much data in a single context, and consider using multiple contexts for different parts of your state.

### Performance Profiling

Use React's built-in Profiler and browser developer tools to identify performance bottlenecks.

## Conclusion

Performance optimization should be an ongoing process. Start with the most impactful optimizations and continuously monitor your application's performance as it evolves.
    `,
    publishedAt: "2023-04-10",
    readingTime: "6 min read",
    category: categories[2],
    author: {
      id: "3",
      name: "Carlos Rodriguez",
      avatar: "/placeholder.svg?height=40&width=40",
    },
  },
  {
    id: "4",
    title: "Introduction to Design Systems",
    slug: "introduction-design-systems",
    excerpt:
      "Learn what design systems are and how they can help maintain consistency across your products and streamline collaboration.",
    content: `
# Introduction to Design Systems

A design system is a collection of reusable components, guided by clear standards, that can be assembled to build any number of applications. This article introduces the concept and benefits of design systems.

## What is a Design System?

A design system consists of:

- UI components (buttons, cards, inputs, etc.)
- Design tokens (colors, typography, spacing, etc.)
- Patterns and guidelines
- Documentation

## Benefits of Design Systems

### Consistency

Design systems ensure visual and functional consistency across products, creating a cohesive user experience regardless of the platform or device.

### Efficiency

With reusable components, teams can:
- Build new features faster
- Avoid duplicating work
- Focus on solving unique problems rather than recreating common elements

### Collaboration

Design systems create a shared language between designers and developers, streamlining the handoff process and reducing miscommunication.

### Scalability

As products grow, design systems provide a structured way to manage complexity and maintain quality.

## Building a Design System

### 1. Audit Existing Interfaces

Start by cataloging existing UI elements to identify patterns and inconsistencies.

### 2. Define Design Tokens

Establish the fundamental design decisions:
- Color palette
- Typography scale
- Spacing units
- Breakpoints

### 3. Create Component Library

Build a library of reusable components, starting with the most basic elements and working up to more complex patterns.

### 4. Document Everything

Comprehensive documentation should include:
- Usage guidelines
- Code examples
- Accessibility considerations
- Interactive examples

### 5. Maintain and Evolve

Design systems are living documents that should evolve with your products and user needs.

## Popular Design Systems

Several companies have created robust design systems:

- Google's Material Design
- Apple's Human Interface Guidelines
- IBM's Carbon Design System
- Shopify's Polaris

## Conclusion

Investing in a design system pays dividends in consistency, efficiency, and collaboration. Whether you're a small startup or a large enterprise, a well-implemented design system can transform your product development process.
    `,
    publishedAt: "2023-03-18",
    readingTime: "5 min read",
    category: categories[3],
    author: {
      id: "4",
      name: "Emma Wilson",
      avatar: "/placeholder.svg?height=40&width=40",
    },
  },
  {
    id: "5",
    title: "The Rise of Edge Computing",
    slug: "rise-edge-computing",
    excerpt:
      "Explore how edge computing is changing the way we process data and enabling new types of applications with reduced latency.",
    content: `
# The Rise of Edge Computing

Edge computing is transforming how we process data by bringing computation closer to data sources. This paradigm shift is enabling new applications and improving performance for existing ones.

## What is Edge Computing?

Edge computing is a distributed computing paradigm that brings computation and data storage closer to the location where it is needed. Rather than relying on a central data center, processing occurs near the "edge" of the network, close to where data is generated.

## Why Edge Computing Matters

### Reduced Latency

By processing data closer to its source, edge computing significantly reduces latency—the time it takes for data to travel from its source to where it's processed and back.

### Bandwidth Conservation

Edge computing reduces the amount of data that needs to be transmitted to central servers, conserving bandwidth and reducing costs.

### Enhanced Privacy and Security

Sensitive data can be processed locally, reducing exposure to potential security breaches during transmission.

### Reliability

Edge computing can continue to function even when connection to the central server is lost or degraded.

## Applications of Edge Computing

### Internet of Things (IoT)

IoT devices generate massive amounts of data. Edge computing allows for:
- Local processing of sensor data
- Immediate response to critical events
- Reduced cloud storage and processing costs

### Autonomous Vehicles

Self-driving cars need to make split-second decisions based on their environment:
- Real-time processing of sensor data
- Immediate response to road conditions
- Operation in areas with poor connectivity

### Augmented Reality

AR applications require minimal latency for a seamless experience:
- Real-time rendering of AR elements
- Responsive interaction with virtual objects
- Reduced motion sickness

### Smart Cities

Urban infrastructure can benefit from localized processing:
- Traffic management systems
- Public safety monitoring
- Utility optimization

## Challenges and Considerations

Despite its benefits, edge computing presents challenges:

- Managing distributed systems
- Ensuring security across multiple edge locations
- Balancing local vs. cloud processing
- Standardizing edge computing platforms

## The Future of Edge Computing

As 5G networks expand and IoT devices proliferate, edge computing will become increasingly important. We can expect:

1. More sophisticated edge AI capabilities
2. Greater integration between edge and cloud computing
3. New business models centered around edge services
4. Specialized hardware designed for edge deployment

## Conclusion

Edge computing represents a fundamental shift in how we architect systems and process data. Organizations that effectively leverage edge computing will be well-positioned to deliver faster, more reliable, and more innovative services.
    `,
    publishedAt: "2023-02-05",
    readingTime: "8 min read",
    category: categories[1],
    author: {
      id: "5",
      name: "David Kim",
      avatar: "/placeholder.svg?height=40&width=40",
    },
  },
  {
    id: "6",
    title: "Understanding Blockchain Beyond Cryptocurrency",
    slug: "blockchain-beyond-cryptocurrency",
    excerpt:
      "Discover the wide-ranging applications of blockchain technology beyond digital currencies, from supply chain to healthcare.",
    content: `
# Understanding Blockchain Beyond Cryptocurrency

While blockchain technology is most commonly associated with cryptocurrencies like Bitcoin, its potential applications extend far beyond digital currencies. This article explores how blockchain is being applied across various industries.

## Blockchain Fundamentals

At its core, blockchain is a distributed ledger technology that records transactions across multiple computers. Key characteristics include:

- Decentralization
- Transparency
- Immutability
- Security through cryptography

## Supply Chain Management

Blockchain offers unprecedented transparency in supply chains:

### Product Provenance

Tracking products from origin to consumer:
- Verifying ethical sourcing
- Confirming authenticity of luxury goods
- Ensuring food safety

### Logistics Optimization

- Real-time tracking of shipments
- Automated payments upon delivery confirmation
- Reduction in paperwork and administrative costs

## Healthcare Applications

Blockchain can address several challenges in healthcare:

### Medical Records

- Secure, patient-controlled health records
- Seamless sharing between providers
- Immutable audit trails

### Pharmaceutical Supply Chain

- Tracking drugs from manufacturer to patient
- Combating counterfeit medications
- Ensuring proper storage conditions

## Legal and Government Services

Governments are exploring blockchain for various services:

### Identity Management

- Self-sovereign identity solutions
- Reduction in identity theft
- Streamlined access to government services

### Land Registry

- Immutable property records
- Reduction in title fraud
- Faster property transfers

## Financial Services Beyond Cryptocurrency

Traditional financial institutions are adopting blockchain:

### Cross-Border Payments

- Faster international transfers
- Reduced fees
- Increased transparency

### Smart Contracts

- Automated execution of agreements
- Reduced need for intermediaries
- Programmable business logic

## Challenges to Widespread Adoption

Despite its potential, blockchain faces hurdles:

- Scalability limitations
- Regulatory uncertainty
- Integration with legacy systems
- Energy consumption concerns
- Education and understanding

## The Future of Blockchain

As the technology matures, we can expect:

1. Increased interoperability between different blockchain networks
2. More user-friendly interfaces hiding technical complexity
3. Hybrid solutions combining blockchain with traditional systems
4. Greater regulatory clarity

## Conclusion

Blockchain technology has the potential to transform numerous industries by enhancing transparency, security, and efficiency. As organizations move beyond experimental pilots to full-scale implementations, we'll continue to discover new applications for this revolutionary technology.
    `,
    publishedAt: "2023-01-20",
    readingTime: "7 min read",
    category: categories[1],
    author: {
      id: "6",
      name: "Sophia Chen",
      avatar: "/placeholder.svg?height=40&width=40",
    },
  },
]

export const getRecentPosts = (count = 3): BlogPost[] => {
  return [...blogPosts]
    .sort((a, b) => new Date(b.publishedAt).getTime() - new Date(a.publishedAt).getTime())
    .slice(0, count)
}

export const getPaginatedPosts = (
  page = 1,
  pageSize = 6,
  categorySlug?: string,
  searchQuery?: string,
): { posts: BlogPost[]; total: number } => {
  let filteredPosts = [...blogPosts]

  // Filter by category if provided
  if (categorySlug) {
    filteredPosts = filteredPosts.filter((post) => post.category.slug === categorySlug)
  }

  // Filter by search query if provided
  if (searchQuery) {
    const query = searchQuery.toLowerCase()
    filteredPosts = filteredPosts.filter(
      (post) =>
        post.title.toLowerCase().includes(query) ||
        post.excerpt.toLowerCase().includes(query) ||
        post.content.toLowerCase().includes(query),
    )
  }

  // Sort by date (newest first)
  filteredPosts.sort((a, b) => new Date(b.publishedAt).getTime() - new Date(a.publishedAt).getTime())

  // Calculate pagination
  const total = filteredPosts.length
  const start = (page - 1) * pageSize
  const end = start + pageSize
  const paginatedPosts = filteredPosts.slice(start, end)

  return {
    posts: paginatedPosts,
    total,
  }
}

export const getPostBySlug = (slug: string): BlogPost | undefined => {
  return blogPosts.find((post) => post.slug === slug)
}
