import 'package:cash_app/db/config.dart';
import 'package:cash_app/ui/components/pages/mobile/onboarding/welcome_screens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WelcomeScreensTablet extends StatefulWidget {
	const WelcomeScreensTablet({super.key});

	@override
	State<WelcomeScreensTablet> createState() => _WelcomeScreensTabletState();
}

class _WelcomeScreensTabletState extends State<WelcomeScreensTablet> {
	final PageController _pageController = PageController();
	int _currentIndex = 0;

	bool get _isLastPage => _currentIndex == pages.length - 1;

	Future<void> _finish(BuildContext context) async {
		final db = Get.find<Config>();
		await db.updateNumberOfLogins();
		if (!context.mounted) return;
		Navigator.pushReplacementNamed(context, '/');
	}

	void _nextPage() {
		if (_isLastPage) {
			_finish(context);
			return;
		}

		_pageController.nextPage(
			duration: const Duration(milliseconds: 320),
			curve: Curves.easeInOut,
		);
	}

	@override
	void dispose() {
		_pageController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		final size = MediaQuery.sizeOf(context);
		final isDesktop = size.width >= 1280;
		final horizontalPadding = isDesktop ? 48.0 : 28.0;

		return Scaffold(
			body: AnimatedContainer(
				duration: const Duration(milliseconds: 250),
				color: pages[_currentIndex].bgColor,
				child: SafeArea(
					child: Padding(
						padding: EdgeInsets.fromLTRB(
							horizontalPadding,
							24,
							horizontalPadding,
							24,
						),
						child: Column(
							children: [
								Row(
									children: [
										Text(
											'CashMate',
											style: TextStyle(
												color: pages[_currentIndex].textColor,
												fontSize: 26,
												fontWeight: FontWeight.bold,
											),
										),
										const Spacer(),
										TextButton(
											onPressed: () => _finish(context),
											style: TextButton.styleFrom(
												foregroundColor: pages[_currentIndex].textColor,
											),
											child: const Text('Skip'),
										),
									],
								),
								const SizedBox(height: 18),
								Expanded(
									child: PageView.builder(
										controller: _pageController,
										itemCount: pages.length,
										onPageChanged: (index) {
											setState(() => _currentIndex = index);
										},
										itemBuilder: (context, index) {
											final page = pages[index];
											return _TabletOnboardingSlide(
												page: page,
												index: index,
												isLastPage: index == pages.length - 1,
												onGetStarted: () => _finish(context),
											);
										},
									),
								),
								const SizedBox(height: 22),
								Row(
									children: [
										Expanded(
											child: Row(
												children: List.generate(
													pages.length,
													(index) => AnimatedContainer(
														duration: const Duration(milliseconds: 220),
														margin: const EdgeInsets.only(right: 10),
														width: index == _currentIndex ? 34 : 10,
														height: 10,
														decoration: BoxDecoration(
															color: index == _currentIndex
																	? pages[_currentIndex].textColor
																	: pages[_currentIndex]
																			.textColor
																			.withOpacity(0.28),
															borderRadius: BorderRadius.circular(999),
														),
													),
												),
											),
										),
										SizedBox(
											height: 56,
											child: OutlinedButton(
												onPressed: _currentIndex == 0
														? null
														: () {
																_pageController.previousPage(
																	duration: const Duration(milliseconds: 320),
																	curve: Curves.easeInOut,
																);
															},
												style: OutlinedButton.styleFrom(
													side: BorderSide(
														color: pages[_currentIndex].textColor.withOpacity(0.32),
													),
													foregroundColor: pages[_currentIndex].textColor,
													shape: RoundedRectangleBorder(
														borderRadius: BorderRadius.circular(18),
													),
												),
												child: const Text('Back'),
											),
										),
										const SizedBox(width: 12),
										SizedBox(
											height: 56,
											child: ElevatedButton.icon(
												onPressed: _nextPage,
												style: ElevatedButton.styleFrom(
													backgroundColor:
															pages[_currentIndex].textColor.computeLuminance() > 0.5
																	? Colors.black
																	: Colors.white,
													foregroundColor:
															pages[_currentIndex].textColor.computeLuminance() > 0.5
																	? Colors.white
																	: Colors.black,
													padding: const EdgeInsets.symmetric(
														horizontal: 22,
														vertical: 16,
													),
													shape: RoundedRectangleBorder(
														borderRadius: BorderRadius.circular(18),
													),
												),
												icon: Icon(_isLastPage
														? Icons.check_circle_outline
														: Icons.arrow_forward),
												label: Text(_isLastPage ? 'Get Started' : 'Continue'),
											),
										),
									],
								),
							],
						),
					),
				),
			),
		);
	}
}

class _TabletOnboardingSlide extends StatelessWidget {
	final PageData page;
	final int index;
	final bool isLastPage;
	final VoidCallback onGetStarted;

	const _TabletOnboardingSlide({
		required this.page,
		required this.index,
		required this.isLastPage,
		required this.onGetStarted,
	});

	@override
	Widget build(BuildContext context) {
		final size = MediaQuery.sizeOf(context);
		final isDesktop = size.width >= 1280;
		final imagePanelWidth = isDesktop ? size.width * 0.38 : size.width * 0.42;

		return LayoutBuilder(
			builder: (context, constraints) {
				return Row(
					children: [
						Expanded(
							flex: 11,
							child: Center(
								child: ConstrainedBox(
									constraints: const BoxConstraints(maxWidth: 620),
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										mainAxisAlignment: MainAxisAlignment.center,
										children: [
											Container(
												padding: const EdgeInsets.symmetric(
													horizontal: 14,
													vertical: 8,
												),
												decoration: BoxDecoration(
													color: page.textColor.withOpacity(0.1),
													borderRadius: BorderRadius.circular(999),
													border: Border.all(
														color: page.textColor.withOpacity(0.16),
													),
												),
												child: Text(
													'Step ${index + 1} of ${pages.length}',
													style: TextStyle(
														color: page.textColor,
														fontWeight: FontWeight.w600,
													),
												),
											),
											const SizedBox(height: 28),
											Text(
												page.title ?? '',
												style: TextStyle(
													color: page.textColor,
													fontSize: isDesktop ? 54 : 44,
													fontWeight: FontWeight.bold,
													height: 1.02,
													letterSpacing: -1.2,
												),
											),
											const SizedBox(height: 22),
											Text(
												page.body ?? '',
												style: TextStyle(
													color: page.textColor.withOpacity(0.88),
													fontSize: isDesktop ? 20 : 18,
													height: 1.5,
												),
											),
											const SizedBox(height: 30),
											Wrap(
												spacing: 12,
												runSpacing: 12,
												children: [
													_FeaturePill(
														icon: Icons.point_of_sale_outlined,
														text: 'Fast checkout',
														textColor: page.textColor,
													),
													_FeaturePill(
														icon: Icons.inventory_2_outlined,
														text: 'Live stock tracking',
														textColor: page.textColor,
													),
													_FeaturePill(
														icon: Icons.analytics_outlined,
														text: 'Clear business insights',
														textColor: page.textColor,
													),
												],
											),
											const SizedBox(height: 28),
											if (isLastPage)
												SizedBox(
													height: 58,
													child: ElevatedButton.icon(
														onPressed: onGetStarted,
														style: ElevatedButton.styleFrom(
															backgroundColor:
																	page.textColor.computeLuminance() > 0.5
																			? Colors.black
																			: Colors.white,
															foregroundColor:
																	page.textColor.computeLuminance() > 0.5
																			? Colors.white
																			: Colors.black,
															padding: const EdgeInsets.symmetric(
																horizontal: 26,
																vertical: 16,
															),
															shape: RoundedRectangleBorder(
																borderRadius: BorderRadius.circular(18),
															),
														),
														icon: const Icon(Icons.rocket_launch_outlined),
														label: const Text('Launch CashMate'),
													),
												),
										],
									),
								),
							),
						),
						const SizedBox(width: 28),
						Expanded(
							flex: 9,
							child: Center(
								child: Container(
									width: imagePanelWidth,
									constraints: BoxConstraints(
										maxWidth: isDesktop ? 520 : 460,
										maxHeight: constraints.maxHeight * 0.9,
									),
									padding: const EdgeInsets.all(28),
									decoration: BoxDecoration(
										color: Colors.white.withOpacity(0.3),
										borderRadius: BorderRadius.circular(34),
										border: Border.all(
											color: page.textColor.withOpacity(0.12),
										),
										boxShadow: [
											BoxShadow(
												color: Colors.black.withOpacity(0.08),
												blurRadius: 30,
												offset: const Offset(0, 18),
											),
										],
									),
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											Row(
												children: [
													Container(
														width: 54,
														height: 54,
														decoration: BoxDecoration(
															color: page.textColor.withOpacity(0.12),
															borderRadius: BorderRadius.circular(18),
														),
														child: Icon(
															page.icon ?? Icons.auto_awesome,
															color: page.textColor,
															size: 28,
														),
													),
													const SizedBox(width: 14),
													Expanded(
														child: Text(
															page.title?.replaceAll('\n', ' ') ?? '',
															maxLines: 2,
															overflow: TextOverflow.ellipsis,
															style: TextStyle(
																color: page.textColor,
																fontSize: 20,
																fontWeight: FontWeight.bold,
															),
														),
													),
												],
											),
											const SizedBox(height: 24),
											Expanded(
												child: Container(
													width: double.infinity,
													padding: const EdgeInsets.all(18),
													decoration: BoxDecoration(
														color: Colors.white.withOpacity(0.38),
														borderRadius: BorderRadius.circular(28),
													),
													child: Center(
														child: Image.asset(
															page.image_url ?? '',
															fit: BoxFit.contain,
														),
													),
												),
											),
											const SizedBox(height: 18),
											Container(
												padding: const EdgeInsets.all(18),
												decoration: BoxDecoration(
													color: Colors.white.withOpacity(0.38),
													borderRadius: BorderRadius.circular(24),
												),
												child: Column(
													crossAxisAlignment: CrossAxisAlignment.start,
													children: [
														Text(
															'Why this matters',
															style: TextStyle(
																color: page.textColor,
																fontWeight: FontWeight.w700,
																fontSize: 15,
															),
														),
														const SizedBox(height: 8),
														Text(
															page.body ?? '',
															style: TextStyle(
																color: page.textColor.withOpacity(0.82),
																height: 1.45,
															),
														),
													],
												),
											),
										],
									),
								),
							),
						),
					],
				);
			},
		);
	}
}

class _FeaturePill extends StatelessWidget {
	final IconData icon;
	final String text;
	final Color textColor;

	const _FeaturePill({
		required this.icon,
		required this.text,
		required this.textColor,
	});

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
			decoration: BoxDecoration(
				color: Colors.white.withOpacity(0.16),
				borderRadius: BorderRadius.circular(999),
				border: Border.all(color: textColor.withOpacity(0.14)),
			),
			child: Row(
				mainAxisSize: MainAxisSize.min,
				children: [
					Icon(icon, size: 18, color: textColor),
					const SizedBox(width: 8),
					Text(
						text,
						style: TextStyle(
							color: textColor,
							fontWeight: FontWeight.w600,
						),
					),
				],
			),
		);
	}
}
