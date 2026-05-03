<script setup>
const features = [
    {
        title: 'Lightning Fast',
        description: 'Optimized for speed with instant page loads and smooth transitions that keep users engaged.',
        svg: `<svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z" /></svg>`,
    },
    {
        title: 'Secure by Default',
        description: 'Enterprise-grade security built in from the ground up. Your data is always protected.',
        svg: `<svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z" /></svg>`,
    },
    {
        title: 'Easy Integration',
        description: 'Connect with your favorite tools through our flexible API and ready-made integrations.',
        svg: `<svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M14.25 6.087c0-.355.186-.676.401-.959.221-.29.349-.634.349-1.003 0-1.036-1.007-1.875-2.25-1.875s-2.25.84-2.25 1.875c0 .369.128.713.349 1.003.215.283.401.604.401.959v0a.64.64 0 01-.657.643 48.39 48.39 0 01-4.163-.3c.186 1.613.293 3.25.315 4.907a.656.656 0 01-.658.663v0c-.355 0-.676-.186-.959-.401a1.647 1.647 0 00-1.003-.349c-1.036 0-1.875 1.007-1.875 2.25s.84 2.25 1.875 2.25c.369 0 .713-.128 1.003-.349.283-.215.604-.401.959-.401v0c.31 0 .555.26.532.57a48.039 48.039 0 01-.642 5.056c1.518.19 3.058.309 4.616.354a.64.64 0 00.657-.643v0c0-.355-.186-.676-.401-.959a1.647 1.647 0 01-.349-1.003c0-1.035 1.008-1.875 2.25-1.875 1.243 0 2.25.84 2.25 1.875 0 .369-.128.713-.349 1.003-.215.283-.4.604-.4.959v0c0 .333.277.599.61.58a48.1 48.1 0 005.427-.63 48.05 48.05 0 00.582-4.717.532.532 0 00-.533-.57v0c-.355 0-.676.186-.959.401-.29.221-.634.349-1.003.349-1.035 0-1.875-1.007-1.875-2.25s.84-2.25 1.875-2.25c.37 0 .713.128 1.003.349.283.215.604.401.96.401v0a.656.656 0 00.658-.663 48.422 48.422 0 00-.37-5.36c-1.886.342-3.81.574-5.766.689a.578.578 0 01-.61-.58v0z" /></svg>`,
    },
];
</script>

<template>
    <section class="bg-gray-50">
        <div class="mx-auto max-w-7xl px-4 py-16 sm:px-6 sm:py-24 lg:px-8">
            <div class="mx-auto mb-12 max-w-2xl text-center">
                <h2 class="text-3xl font-bold tracking-tight text-gray-900 sm:text-4xl">
                    Everything you need
                </h2>
                <p class="mt-4 text-lg text-gray-600">
                    Powerful features designed to help you work smarter, not harder.
                </p>
            </div>

            <div class="grid gap-8 sm:grid-cols-2 lg:grid-cols-3">
                <div
                    v-for="feature in features"
                    :key="feature.title"
                    class="rounded-lg bg-white p-8 shadow-sm ring-1 ring-gray-200 transition hover:shadow-md hover:ring-gray-300"
                >
                    <div class="mb-4 inline-flex h-12 w-12 items-center justify-center rounded-lg bg-gray-900 text-white" v-html="feature.svg" />
                    <h3 class="text-lg font-semibold text-gray-900">
                        {{ feature.title }}
                    </h3>
                    <p class="mt-3 text-sm leading-relaxed text-gray-600">
                        {{ feature.description }}
                    </p>
                </div>
            </div>
        </div>
    </section>
</template>
