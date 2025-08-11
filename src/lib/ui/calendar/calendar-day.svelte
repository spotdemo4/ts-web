<script lang="ts">
	import { buttonVariants } from '$lib/ui/button/index.js';
	import { cn } from '$lib/utils.js';
	import { Calendar as CalendarPrimitive } from 'bits-ui';

	let {
		ref = $bindable(null),
		class: className,
		...restProps
	}: CalendarPrimitive.DayProps = $props();
</script>

<CalendarPrimitive.Day
	bind:ref
	class={cn(
		buttonVariants({ variant: 'ghost' }),
		'flex size-(--cell-size) flex-col items-center justify-center gap-1 p-0 leading-none font-normal whitespace-nowrap select-none',
		'[&[data-today]:not([data-selected])]:bg-accent [&[data-today]:not([data-selected])]:text-crust [&[data-today][data-disabled]]:text-muted-foreground',
		// Selected
		'data-[selected]:bg-surface data-[selected]:text-text',
		// Outside months
		'[&[data-outside-month]:not([data-selected])]:text-subtext [&[data-outside-month]:not([data-selected])]:hover:text-text',
		// Disabled
		'data-[disabled]:text-muted-foreground data-[disabled]:pointer-events-none data-[disabled]:opacity-50',
		// Unavailable
		'data-[unavailable]:text-muted-foreground data-[unavailable]:line-through',
		// hover
		'dark:hover:text-text',
		// focus
		'focus:border-ring focus:ring-ring/50 focus:relative',
		// inner spans
		'[&>span]:text-xs [&>span]:opacity-70',
		className
	)}
	{...restProps}
/>
