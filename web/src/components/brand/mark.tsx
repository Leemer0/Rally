import Image from "next/image";
import { cn } from "@/lib/utils";

export function BrandMark({ className }: { className?: string }) {
  return (
    <Image
      src="/brand/winged-o.png"
      alt="Outly"
      width={1024}
      height={512}
      priority
      className={cn("h-9 w-[4.5rem] object-contain", className)}
    />
  );
}
