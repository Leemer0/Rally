import Image from "next/image";
import { cn } from "@/lib/utils";

type DevicePreviewProps = {
  src?: string;
  alt?: string;
  priority?: boolean;
  className?: string;
  sizes?: string;
};

export function DevicePreview({
  src = "/product/explore-v2.png",
  alt = "Outly showing tonight's venues on the map",
  priority = false,
  className,
  sizes = "(max-width: 640px) 58vw, 320px",
}: DevicePreviewProps) {
  return (
    <div
      className={cn(
        "overflow-hidden rounded-[2.65rem] border border-white/22 bg-[#030508] p-[7px] shadow-[0_32px_90px_rgba(0,0,0,.48)]",
        className,
      )}
    >
      <Image
        src={src}
        alt={alt}
        width={1206}
        height={2622}
        priority={priority}
        sizes={sizes}
        className="h-auto w-full rounded-[2.18rem]"
      />
    </div>
  );
}
