import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:partition_app/features/partition/services/calendar_service.dart';
import 'package:partition_app/core/network/api_exception.dart';

/// 일정 등록 모달
class ScheduleRegistrationModal extends StatefulWidget {
  final DateTime selectedDate;
  final VoidCallback? onSuccess; // 등록 성공 시 호출될 콜백
  
  const ScheduleRegistrationModal({
    super.key,
    required this.selectedDate,
    this.onSuccess,
  });

  @override
  State<ScheduleRegistrationModal> createState() => _ScheduleRegistrationModalState();
}

class _ScheduleRegistrationModalState extends State<ScheduleRegistrationModal> {
  final TextEditingController _scheduleController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final CalendarService _calendarService = CalendarService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 모달이 열린 후 포커스를 설정하여 키보드가 자동으로 나타나도록 함
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _scheduleController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    return '${date.year}년 ${date.month}월 ${date.day}일 (${weekdays[date.weekday % 7]})';
  }

  String _formatDateToApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _handleRegister() async {
    final scheduleText = _scheduleController.text.trim();
    if (scheduleText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('일정 내용을 입력해주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dateString = _formatDateToApi(widget.selectedDate);
      await _calendarService.registerSchedule(
        content: scheduleText,
        date: dateString,
      );

      if (!mounted) return;

      // 등록 성공 시 모달 닫기
      Navigator.of(context).pop();
      
      // 콜백 호출하여 캘린더 갱신
      widget.onSuccess?.call();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_formatDate(widget.selectedDate)} 일정이 등록되었습니다.'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      String errorMessage = '일정 등록에 실패했습니다.';
      if (e is ApiException) {
        errorMessage = e.message ?? errorMessage;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      alignment: Alignment.center, // 중앙 정렬
      insetPadding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: screenHeight * 0.25, // 상하 여백 추가
      ),
      child: Container(
        width: double.infinity,
        height: screenHeight * 0.4, // 입력 필드 축소에 맞춰 모달 높이 축소
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white,
            width: 0.5,
          ),
          gradient: const RadialGradient(
            center: Alignment(-0.1212, -0.1178),
            radius: 1.6319,
            colors: [
              Color.fromRGBO(255, 255, 255, 0.10),
              Color.fromRGBO(255, 255, 255, 0.15),
            ],
            stops: [0.0, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.25),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                  // 제목
                  Text(
                    '일정 등록하기',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Pretendard Variable',
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // 선택된 날짜 표시
                  Text(
                    _formatDate(widget.selectedDate),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Pretendard Variable',
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // 부제목
                  const Text(
                    '등록된 일정은 룸메이트와 공유됩니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      fontFamily: 'Pretendard Variable',
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20), // 여백 축소
                  // 입력 영역
                  SizedBox(
                    height: 80, // 고정 높이로 크기 절반으로 축소
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 0.5,
                        ),
                        gradient: const RadialGradient(
                          center: Alignment(-0.1212, -0.1178),
                          radius: 1.6319,
                          colors: [
                            Color.fromRGBO(255, 255, 255, 0.10),
                            Color.fromRGBO(255, 255, 255, 0.15),
                          ],
                          stops: [0.0, 1.0],
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: TextField(
                            controller: _scheduleController,
                            focusNode: _focusNode,
                            autofocus: true,
                            maxLines: 2,
                            maxLength: 30,
                            maxLengthEnforcement: MaxLengthEnforcement.enforced,
                            textAlignVertical: TextAlignVertical.top,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Pretendard Variable',
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: '일정을 입력해주세요...',
                              hintStyle: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontFamily: 'Pretendard Variable',
                              ),
                              counterText: '', // 글자 수 카운터 숨기기
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20), // 여백 축소
                  // 등록하기 버튼
                  _buildRegisterButton(),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return _buildGlassmorphismButton(
      text: '등록하기',
      onTap: _isLoading ? () {} : _handleRegister,
    );
  }

  Widget _buildGlassmorphismButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 266,
        height: 45.327,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white,
            width: 0.5,
          ),
          gradient: const RadialGradient(
            center: Alignment(-0.1212, -0.1178),
            radius: 1.6319,
            colors: [
              Color.fromRGBO(255, 255, 255, 0.10),
              Color.fromRGBO(255, 255, 255, 0.15),
            ],
            stops: [0.0, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.25),
              blurRadius: 30,
              spreadRadius: 0,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Center(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Pretendard Variable',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

