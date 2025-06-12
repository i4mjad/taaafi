"use client"
import React, { useRef } from "react"
import { useScroll, useTransform, motion, type MotionValue } from "framer-motion"

export const ContainerScroll = ({
  titleComponent,
  children,
  useSimpleCard = false,
}: {
  titleComponent: string | React.ReactNode
  children: React.ReactNode
  useSimpleCard?: boolean
}) => {
  const containerRef = useRef<HTMLDivElement>(null)
  const { scrollYProgress } = useScroll({
    target: containerRef,
  })
  const [isMobile, setIsMobile] = React.useState(false)

  React.useEffect(() => {
    const checkMobile = () => {
      setIsMobile(window.innerWidth <= 768)
    }
    checkMobile()
    window.addEventListener("resize", checkMobile)
    return () => {
      window.removeEventListener("resize", checkMobile)
    }
  }, [])

  const scaleDimensions = () => {
    return isMobile ? [0.7, 0.9] : [1.05, 1]
  }

  const rotate = useTransform(scrollYProgress, [0, 1], [20, 0])
  const scale = useTransform(scrollYProgress, [0, 1], scaleDimensions())
  const translate = useTransform(scrollYProgress, [0, 1], [0, -100])

  return (
    <div className="h-[60rem] md:h-[80rem] flex items-center justify-center relative pt-2 px-2 md:pt-20 md:px-20" ref={containerRef}>
      <div
        className="w-full relative"
        style={{
          perspective: "1000px",
        }}
      >
        <Header translate={translate} titleComponent={titleComponent} />
        {useSimpleCard ? (
          <SimpleCard rotate={rotate} translate={translate} scale={scale}>
            {children}
          </SimpleCard>
        ) : (
          <Card rotate={rotate} translate={translate} scale={scale}>
            {children}
          </Card>
        )}
      </div>
    </div>
  )
}

export const Header = ({ translate, titleComponent }: any) => {
  return (
    <motion.div
      style={{
        translateY: translate,
      }}
      className="div max-w-5xl mx-auto text-center"
    >
      {titleComponent}
    </motion.div>
  )
}

export const Card = ({
  rotate,
  scale,
  translate,
  children,
}: {
  rotate: MotionValue<number>
  scale: MotionValue<number>
  translate: MotionValue<number>
  children: React.ReactNode
}) => {
  return (
    <motion.div
      style={{
        rotateX: rotate,
        scale,
      }}
      className="max-w-5xl -mt-12 mx-auto h-[30rem] md:h-[40rem] w-full border-4 border-[#6C6C6C] p-2 md:p-6 bg-[#222222] rounded-[30px]"
    >
      <div className="h-full w-full overflow-hidden rounded-2xl bg-gray-100 dark:bg-zinc-900 md:rounded-2xl md:p-4">
        {children}
      </div>
    </motion.div>
  )
}

export const SimpleCard = ({
  rotate,
  scale,
  translate,
  children,
}: {
  rotate: MotionValue<number>
  scale: MotionValue<number>
  translate: MotionValue<number>
  children: React.ReactNode
}) => {
  return (
    <motion.div
      style={{
        rotateX: rotate,
        scale,
      }}
      className="max-w-md -mt-12 mx-auto w-full"
    >
      {children}
    </motion.div>
  )
}
