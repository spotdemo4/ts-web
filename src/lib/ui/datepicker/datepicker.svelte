<script lang="ts">
	import type { DateValue } from '@internationalized/date';
	import { buttonVariants } from '$lib/ui/button/index.js';
	import { Calendar } from '$lib/ui/calendar/index.js';
	import * as Popover from '$lib/ui/popover/index.js';
	import { DateFormatter, getLocalTimeZone } from '@internationalized/date';
	import CalendarIcon from '@lucide/svelte/icons/calendar';
	import { cn } from '$lib/utils.js';

	let {
		ref = $bindable(null),
		value = $bindable(),
		onchange
	}: {
		ref?: HTMLElement | null;
		value?: DateValue;
		onchange?: (date?: DateValue) => void;
	} = $props();

	const df = new DateFormatter('en-US', {
		dateStyle: 'long'
	});
</script>

<Popover.Root>
	<Popover.Trigger
		class={cn(
			buttonVariants({
				variant: 'input',
				class: 'bg-based text-md md:text-sm'
			})
		)}
	>
		<CalendarIcon />
		{value ? df.format(value.toDate(getLocalTimeZone())) : 'Pick a date'}
	</Popover.Trigger>
	<Popover.Content bind:ref class="bg-based w-auto p-0">
		<Calendar
			type="single"
			bind:value
			onValueChange={(v) => {
				onchange?.(v);
			}}
		/>
	</Popover.Content>
</Popover.Root>
